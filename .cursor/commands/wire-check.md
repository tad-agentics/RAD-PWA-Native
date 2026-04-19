## /wire-check [feature-name?]

Scripted audit that detects "shell of an app" symptoms — code that compiles and looks correct in screenshots but isn't actually wired between Backend and Frontend. Runs after Frontend completes a feature and before QA dispatch. Also runs as Pass 0 inside QA and as `/dogfood` pre-flight.

Usage: `/wire-check` (whole repo) · `/wire-check [feature-name]` (single feature scope)

Exits with PASS / WARN / BLOCKING. WARN and BLOCKING write a report to `artifacts/qa-reports/wire-check-[feature]-[date].md`.

---

## What this catches

| Symptom | Why it ships as a "shell" |
|---|---|
| Mock data still imported in active routes | Frontend forgot to swap mocks for Supabase queries — UI looks right with hardcoded data |
| `useMutation` without `invalidateQueries` | Mutations succeed server-side but UI shows stale data after action |
| `supabase.functions.invoke('foo')` with no matching `supabase/functions/foo/` | Function call fires, gets 404, error is swallowed |
| Edge Function input shape mismatch with hook payload | Function 200s with empty result; hook returns nothing; UI shows empty state forever |
| Screen reads from wrong table (typo, wrong entity) | RLS returns 0 rows silently — empty state shows but data exists |
| `// TODO: wire backend`, `// mock data`, `mockData =` in active code | Self-evident |
| Auth-protected route missing under `_app/` layout | Route works without session — RLS is the only thing keeping data private |
| Hook defined but never used; screen reads from inline `supabase.from()` | Hook abstraction broken; query keys won't match across screens |
| TanStack Query key not registered in `src/lib/query-keys.ts` | Cross-screen invalidation will miss this query |

---

## Checks (run in order, fail-fast on BLOCKING)

### 1. Mock-data leak (BLOCKING if any hit)

```bash
# Active code must not import from src/design-handoff/
grep -rn "from ['\"].*design-handoff" src/routes src/components src/hooks src/lib 2>/dev/null

# Active code must not declare mockData / fakeData / sampleData / hardcoded arrays
# named like mock*. Whitelist: src/design-handoff/, *.test.*, *.stories.*
grep -rEn "(mock|fake|sample|dummy|stub)(Data|Items|Users|Entries)\s*=" \
  src/routes src/components src/hooks src/lib 2>/dev/null

# No "TODO: wire" / "TODO: backend" / "TODO: replace mock" markers
grep -rEn "TODO.*?(wire|backend|replace.*mock|hook.*up)" \
  src/routes src/components src/hooks src/lib 2>/dev/null
```

### 2. Mutation invalidation (BLOCKING per missing pair)

For every `useMutation` block in `src/`:

- Must contain an `onSuccess` handler
- `onSuccess` must call `queryClient.invalidateQueries`
- Optimistic mutations must also have `onError` rollback and `onSettled` invalidation

Heuristic grep:

```bash
# Find useMutation calls and check 30 lines after for invalidateQueries
grep -rln "useMutation" src/ | while read f; do
  awk '/useMutation/,/^})/' "$f" | grep -L "invalidateQueries" && echo "MISSING in $f"
done
```

Flag each file where a mutation lacks invalidation. The agent reads the flagged file and confirms case-by-case (greps over multi-line JSX produce false positives — the report lists candidates, the agent verifies).

### 3. Edge Function call → function exists (BLOCKING per orphan call)

Every `supabase.functions.invoke('name', ...)` in frontend must have a matching `supabase/functions/name/index.ts`.

```bash
# Extract all invoked function names
grep -rEho "supabase\.functions\.invoke\(['\"]([^'\"]+)['\"]" src/ | \
  sed -E "s/.*invoke\(['\"]([^'\"]+).*/\1/" | sort -u > /tmp/invoked.txt

# List all deployed function names
ls supabase/functions/ 2>/dev/null | grep -v "^_" > /tmp/deployed.txt

# Diff
comm -23 /tmp/invoked.txt /tmp/deployed.txt
# Output = invoked but not deployed → BLOCKING
```

### 4. Edge Function input shape match (WARN per mismatch — agent confirms)

For each invoked function:
- Read the hook's invocation: `supabase.functions.invoke('name', { body: {...shape...} })`
- Read `supabase/functions/name/index.ts` Zod schema (or first `req.json()` destructure)
- Diff the keys. Mismatched keys → WARN (Zod will reject at runtime; better to catch now)

Heuristic only — agent reviews the WARN list and elevates real mismatches to BLOCKING.

### 5. Auth boundary (BLOCKING per leak)

Every route file under `src/routes/_app/` must inherit the auth-guard layout. Routes outside `_app/` and `_auth/` and `_index` should not exist.

```bash
# Routes outside the three allowed top-level groups
find src/routes -mindepth 2 -maxdepth 2 -type d | \
  grep -vE "src/routes/(_app|_auth|_index)"
# Any output → BLOCKING (route placed outside auth boundary)
```

### 6. Query-key registry (WARN per unregistered key)

Every `useQuery({ queryKey: [...], ... })` in `src/` should pull its key from `src/lib/query-keys.ts` (not inline literal arrays). Inline keys risk cross-screen invalidation drift.

```bash
# Find inline queryKey arrays NOT referencing queryKeys.*
grep -rEn "queryKey:\s*\[" src/ | grep -v "queryKeys\." | grep -v "src/lib/query-keys.ts"
```

Flag each as WARN. Agent decides: register in `query-keys.ts` (preferred) or accept (if truly one-off).

### 7. Hook uses (WARN per direct supabase call in routes)

Routes should call hooks (`useEntries()`), not `supabase.from('entries')` directly. Direct calls fragment query keys.

```bash
grep -rEn "supabase\.from\(" src/routes/
# Any hit → WARN. Allowed: src/hooks/, src/lib/data/.
```

### 8. Realtime subscriptions (WARN if tech-spec lists realtime but none found)

If `artifacts/docs/tech-spec.md` mentions `supabase.channel(` or "realtime", at least one `supabase.channel(` call must exist in `src/`. Otherwise WARN — likely missed wiring.

### 9. Build still passes (BLOCKING if not)

```bash
npm run build 2>&1 | tail -30
```

Zero TypeScript errors. If any unused-import warnings on files touched in this feature's diff, list them as WARN.

### 10. database.types.ts freshness (BLOCKING if stale)

If any migration in `supabase/migrations/` is newer than `src/lib/database.types.ts`, the FE's row types are stale — silent runtime mismatches.

```bash
NEWEST_MIGRATION=$(ls -t supabase/migrations/*.sql 2>/dev/null | head -1)
TYPES_FILE="src/lib/database.types.ts"
if [ -n "$NEWEST_MIGRATION" ] && [ -f "$TYPES_FILE" ]; then
  if [ "$NEWEST_MIGRATION" -nt "$TYPES_FILE" ]; then
    echo "STALE: $NEWEST_MIGRATION is newer than $TYPES_FILE"
    echo "Run: supabase gen types typescript --project-id <ref> > $TYPES_FILE"
  fi
fi
```

### 11. Edge Function response Zod parse (WARN per missing parse)

Every hook that calls `supabase.functions.invoke` should parse the response through a Zod schema before returning data. Without this, response shape drift breaks the UI silently.

```bash
# Find invoke calls and check the same file/function for .parse(
grep -rln "supabase\.functions\.invoke" src/hooks src/lib/data 2>/dev/null | while read f; do
  grep -q "\.parse(" "$f" || echo "NO ZOD PARSE in $f (Edge Function response not validated)"
done
```

### 12. Security greps (BLOCKING per hit)

Cheap preventive checks — `/security-audit` runs the deep scan at pre-deploy; this catches the obvious ones at build time so they don't reach pre-deploy.

```bash
# 12a. SUPABASE_SERVICE_ROLE_KEY referenced in frontend code
grep -rn "SUPABASE_SERVICE_ROLE_KEY\|service_role" src/ 2>/dev/null

# 12b. LLM provider secrets referenced in src/ (do not install or read these client-side)
# All LLM API keys live in Edge Function secrets only — frontend uses supabase.functions.invoke
grep -rEn "(OPENROUTER|OPENAI|ANTHROPIC)_API_KEY" src/ 2>/dev/null

# 12c. console.log of tokens / secrets / passwords
grep -rEn "console\.(log|error|debug|warn)\([^)]*(token|secret|password|api[_-]?key|jwt|access_token|refresh_token)" src/ 2>/dev/null

# 12d. dangerouslySetInnerHTML
grep -rn "dangerouslySetInnerHTML" src/ 2>/dev/null

# 12e. Edge Function CORS wildcard in production code (allow only in _shared/cors.ts dev mode)
grep -rn "Access-Control-Allow-Origin.*\*" supabase/functions/ 2>/dev/null | grep -v "_shared/cors.ts"

# 12f. Edge Function missing JWT verification when Trust mode is Edge-validated
# (heuristic: function file must reference auth.getUser() or verifyJWT helper)
for fn in supabase/functions/*/index.ts; do
  [ -f "$fn" ] || continue
  case "$(dirname "$fn")" in
    *-webhook|*cron*|*-admin) continue ;;  # webhook/cron/admin use service role
  esac
  grep -q "auth\.getUser\|verifyJWT\|getUser(" "$fn" || \
    echo "NO JWT VERIFICATION in $fn (Edge-validated function must verify JWT)"
done
```

---

## Per-feature scope (when invoked as `/wire-check [feature-name]`)

Constrain checks 1–9 to files that match the feature's scope from `artifacts/plans/build-plan.md`:
- Backend: tables, Edge Functions listed for this feature
- Frontend: routes under `src/routes/_app/[feature]/` plus any hooks listed in the feature's Wiring Map

Whole-repo mode runs across everything.

---

## Output format

Write `artifacts/qa-reports/wire-check-[feature|repo]-[YYYY-MM-DD].md`:

```markdown
# Wire Check — [feature | repo]
**Date:** YYYY-MM-DD
**Status:** PASS | WARN | BLOCKING

## Summary
- Mock leaks: N
- Missing invalidations: N
- Orphan function calls: N
- Shape mismatches: N (warn — agent verifies)
- Auth boundary leaks: N
- Unregistered query keys: N
- Direct supabase calls in routes: N
- Realtime gaps: N
- Build: PASS / FAIL

## BLOCKING
[file:line — what's wrong — suggested fix]

## WARN
[file:line — what to verify]

## PASS notes
[any positive confirmations worth recording]
```

---

## Gates

- **In `/feature` Step 2:** Frontend Developer runs `/wire-check [feature]` after committing screens. Must be PASS before signaling completion to Tech Lead. WARN allowed if each is annotated with a one-line justification in the report.
- **In QA Pass 0:** runs as the first pass; BLOCKING here halts the other 5 passes (no point checking visual fidelity if data isn't wired).
- **In `/dogfood`:** runs as automatic pre-flight; BLOCKING halts the manual session — no use dogfooding a shell.

## Notes

- This command is scripted (greps + npm build). It does not call agents. The Tech Lead or whoever triggers `/feature` runs it.
- False-positive rate is intentionally low — checks rely on conventions RAD already enforces (`useQuery`/`useMutation` patterns, route layout, function naming).
- Update this command when new wiring patterns emerge (e.g., Realtime Presence, broadcast channels). Failure modes in production = additions here.
