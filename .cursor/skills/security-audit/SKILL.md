---
name: security-audit
description: Security audit — OWASP Top 10 + Supabase-specific checks + dependency supply chain scan. Run during pre-handoff before deploying to production.
disable-model-invocation: true
---

# Security Audit — Pre-Deploy Safety Check

Run this during pre-handoff, before the DevOps agent deploys. Two modes:

- **Standard (default):** High-confidence findings only (8/10 confidence gate). Zero false positives tolerated.
- **Comprehensive (`--comprehensive`):** Lower bar (2/10). Monthly deep scan. Includes informational findings.

## Phase 1 — Secrets Archaeology

Scan the entire repo history for leaked secrets:

```bash
# Check current codebase for secrets
grep -rn "sk_live_\|sk-or-\|re_\|whsec_\|SUPABASE_SERVICE_ROLE_KEY\s*=" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.env*" . 2>/dev/null | grep -v node_modules | grep -v ".env.example"

# Check git history for secrets that were committed then removed
git log --all --diff-filter=D -p -- "*.env" "*.env.local" 2>/dev/null | grep -E "sk_live_|sk-or-|re_|whsec_|SERVICE_ROLE" | head -20

# Check build output for leaked secrets
if [ -d "dist" ] || [ -d "build" ]; then
  grep -rn "SERVICE_ROLE\|sk-or-\|sk_live_\|re_\|whsec_" dist/ build/ 2>/dev/null
fi
```

**BLOCKING** if any secret found in current code or build output.
**INFORMATIONAL** if found in git history (recommend `git filter-repo` cleanup).

## Phase 2 — Dependency Supply Chain

```bash
# Check for known vulnerabilities
npm audit --production 2>/dev/null || echo "npm audit failed"

# Check for suspicious packages (typosquatting, very new, low download count)
# Look at direct dependencies only
cat package.json | grep -A 100 '"dependencies"' | grep -B 100 '}'
```

**BLOCKING** if `npm audit` shows critical or high severity.
**INFORMATIONAL** for moderate/low.

## Phase 3 — Supabase RLS Verification

```bash
# List all tables and their RLS status
# Must be run with Supabase MCP or local supabase CLI
supabase db lint 2>/dev/null || echo "Run 'supabase db lint' manually"
```

Manual checks:
- Every table in `supabase/migrations/` has `ALTER TABLE ... ENABLE ROW LEVEL SECURITY`
- No RLS policy uses `USING (true)` on user-owned tables (public read-only tables like enums are OK)
- SELECT policies filter by `auth.uid() = user_id`
- INSERT policies enforce `auth.uid() = user_id` (no client-side user_id injection)
- UPDATE/DELETE policies scope to owner: `USING (auth.uid() = user_id)`
- No table has RLS disabled after being enabled

**BLOCKING** if any user-data table missing RLS or has `USING (true)`.

## Phase 4 — Edge Function Security

For each Edge Function in `supabase/functions/`:

1. **CORS check** — imports `corsHeaders` from `_shared/cors.ts`, handles OPTIONS preflight
2. **CORS production origin** — `_shared/cors.ts` exports `corsHeadersProd` with explicit `ALLOWED_ORIGINS` (no `*` in prod). Functions auto-select based on `Deno.env.get("ENV")`. Verify production deploy uses the prod headers.
3. **JWT verification** — Edge-validated functions (client-callable, not webhook/cron/admin) must call `auth.getUser()` against a JWT-scoped client before any business logic. See `.cursor/rules/security.mdc` template.
4. **Input validation** — uses Zod for all request body parsing. Reject with 400 + `{ code: "VALIDATION_ERROR" }` on parse failure.
5. **Rate limiting** — Edge-validated functions reference `_shared/rate-limit.ts`. Default 30/min/user. LLM functions ≤ 10/min. Payment functions ≤ 5/min.
6. **No secrets in response** — grep function code for any pattern that returns API keys, service role keys, internal URLs, or stack traces.
7. **Webhook signature verification** — any function named `*-webhook` must verify signatures before processing AND insert into `webhook_events` for idempotency.
8. **Service-role guard** — functions named `*-cron`, `*-admin`, or marked Service-role-only must reject client invocation (check trigger source).
9. **Error handling** — no raw exception stack traces, no internal IDs in error responses. Use the standard `{ error: { code, message } }` shape.

**BLOCKING** if missing CORS, missing JWT verification on Edge-validated functions, missing input validation, missing rate limit on Edge-validated functions, secrets in response, missing webhook signature verification, or production CORS using wildcard.

## Phase 5 — OWASP Top 10 (Web Application)

Check against OWASP Top 10 2021 categories relevant to this stack:

| # | Category | What to check | Where |
|---|---|---|---|
| A01 | Broken Access Control | RLS policies, auth guard on all /app routes, direct URL access to other users' data | Phase 3 + frontend routes |
| A02 | Cryptographic Failures | HTTPS only, no plaintext secrets in localStorage, secure cookie flags | Frontend code |
| A03 | Injection | SQL injection via raw queries (should use Supabase client), XSS via dangerouslySetInnerHTML | Frontend + Edge Functions |
| A05 | Security Misconfiguration | Default Supabase keys, verbose error messages, debug mode in production | `.env.example` + build config |
| A07 | Auth Failures | Session handling, token expiry, OAuth callback validation | Auth flow |
| A09 | Logging & Monitoring | No sensitive data in console.log, error boundaries don't leak info | Frontend code |

```bash
# A03 — Check for raw SQL or innerHTML
grep -rn "dangerouslySetInnerHTML\|\.raw\s*(" --include="*.tsx" --include="*.ts" src/ 2>/dev/null | grep -v node_modules

# A05 — Check for debug/development flags in production config
grep -rn "debug.*true\|NODE_ENV.*development" --include="*.ts" --include="*.tsx" src/ 2>/dev/null | grep -v node_modules | grep -v "test"

# A09 — Check for sensitive data logging
grep -rn "console\.log.*password\|console\.log.*token\|console\.log.*secret\|console\.log.*key" --include="*.ts" --include="*.tsx" src/ 2>/dev/null | grep -v node_modules
```

## Section 6 — Web Headers (vercel.json)

```bash
# Required security headers must be present in vercel.json
for header in "Strict-Transport-Security" "X-Content-Type-Options" "Referrer-Policy" "Content-Security-Policy" "Permissions-Policy"; do
  grep -q "$header" vercel.json || echo "MISSING: $header in vercel.json"
done

# CSP must not allow unsafe-inline for scripts (styles can if Tailwind needs)
grep -E "script-src[^;]*unsafe-inline" vercel.json && echo "BLOCKING: CSP allows unsafe-inline for scripts"

# CSP must not allow unsafe-eval
grep -E "unsafe-eval" vercel.json && echo "BLOCKING: CSP allows unsafe-eval"
```

**BLOCKING** if any required header missing, or CSP allows `unsafe-inline` scripts / `unsafe-eval`.

## Section 7 — PII & Data Hygiene

```bash
# No PII in URLs (route params should be opaque IDs, not email)
grep -rEn "/:email|/:phone|/:full_name" src/routes/ 2>/dev/null

# No PII in console statements (extends Phase 5 A09)
grep -rEn "console\.(log|error|debug|warn).*\b(email|phone|birth_date|full_name|address)\b" src/ 2>/dev/null

# Account-deletion path exists if profile data is collected
PROFILE_FIELDS=$(grep -rE "(email|phone|birth_date)" supabase/migrations/ 2>/dev/null | wc -l)
if [ "$PROFILE_FIELDS" -gt 0 ]; then
  ls supabase/functions/delete-account/index.ts 2>/dev/null || echo "MISSING: delete-account Edge Function (right-to-delete)"
fi

# All user-data foreign keys cascade on user delete
grep -rEn "REFERENCES auth\.users" supabase/migrations/ | grep -v "ON DELETE CASCADE" | grep -v "ON DELETE SET NULL"
```

**BLOCKING** if PII appears in URLs or console statements, or if profile data is collected without a `delete-account` flow.

## Section 8 — Storage Buckets

```bash
# Buckets must declare allowed_mime_types and file_size_limit
grep -rE "create_bucket\(" supabase/migrations/ -A 5 2>/dev/null | grep -L "allowed_mime_types\|file_size_limit"

# Public buckets only with explicit Tech Lead annotation
grep -rE "public.*=.*true" supabase/migrations/ 2>/dev/null | grep -v "-- approved-public:"
```

**BLOCKING** if any bucket missing MIME / size limits, or public bucket without `-- approved-public:` annotation in the migration.

## Section 9 — Rate Limiting Coverage

```bash
# Every Edge-validated function (client-callable, non-webhook, non-cron, non-admin)
# must reference rate-limit helper
for fn in supabase/functions/*/index.ts; do
  [ -f "$fn" ] || continue
  case "$(dirname "$fn")" in
    *-webhook|*cron*|*-admin|*_shared*) continue ;;
  esac
  grep -q "rateLimit\|rate_limits" "$fn" || \
    echo "MISSING rate limit in $fn"
done
```

**BLOCKING** if any Edge-validated function missing rate limit. (LLM functions especially — abuse cost is real.)

## Section 10 — Audit Log Coverage

```bash
# If sensitive operations exist (account deletion, payment events, credit grants),
# audit_log table must exist and these ops must write to it
SENSITIVE_OPS=$(ls supabase/functions/ 2>/dev/null | grep -E "delete-account|payment|credit|admin" | wc -l)
if [ "$SENSITIVE_OPS" -gt 0 ]; then
  grep -q "CREATE TABLE audit_log" supabase/migrations/*.sql || echo "MISSING: audit_log table"
  for op in $(ls supabase/functions/ 2>/dev/null | grep -E "delete-account|payment|credit|admin"); do
    grep -q "audit_log" "supabase/functions/$op/index.ts" 2>/dev/null || \
      echo "MISSING audit_log insert in $op"
  done
fi
```

**BLOCKING** if sensitive ops exist without `audit_log` writes.

## Final — Report

Write findings to `artifacts/qa-reports/security-audit-YYYY-MM-DD.md`:

```markdown
# Security Audit — [date]

**Mode:** Standard | Comprehensive
**Findings:** [N BLOCKING, M INFORMATIONAL]

## BLOCKING (must fix before deploy)
- [finding with exact file:line and remediation]

## INFORMATIONAL (fix when convenient)
- [finding]

## Checks Passed
- [ ] No secrets in current code or build output
- [ ] npm audit: 0 critical/high
- [ ] RLS on all user-data tables
- [ ] Edge Functions: CORS + validation + no secret leakage
- [ ] OWASP: no injection, no auth bypass, no misconfig

## Verdict
PASS — safe to deploy | BLOCKED — [N] items must be fixed first
```

For each BLOCKING finding, classify as AUTO-FIX (apply directly) or ESCALATE (requires Tech Lead decision). Apply AUTO-FIX items with atomic commits: `fix(security): [description]`.
