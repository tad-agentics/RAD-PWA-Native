# /feature [name]

Dispatch a complete feature workstream: Backend → Frontend → QA in sequence.
Each step runs as a foreground subagent and must commit before the next is dispatched.

Usage: `/feature auth` or `/feature goal-creation`

## Pre-flight checks

Before dispatching, confirm:
- [ ] Feature `[name]` exists in `artifacts/plans/build-plan.md`
- [ ] Foundation is committed (`feat(foundation): backend infrastructure complete` + `feat(foundation): shared components + landing page + auth screens complete`)
- [ ] All features this one depends on are committed and QA-passed (check build-plan.md dependency graph)
- [ ] `npm run build` passes on current state
- [ ] **Design handoff present for new screens (M4):** if the feature's Frontend Scope in `artifacts/docs/features/[name].md` (or its build-plan context package) names any screen NOT already present in `src/design-handoff/screens/` (or equivalent path from the initial handoff), then `src/design-handoff/new-feature-[name]/` MUST exist and have passed `/design verify new-feature [name]`. Run this scripted check:
  ```bash
  bash .cursor/skills/design-adapters/claude-design-adapter/scripts/check-feature-design-prereq.sh [name]
  ```
  Exit 0 → proceed. Exit 1 → BLOCKING with message: "Feature [name] adds new screens but `src/design-handoff/new-feature-[name]/` is missing. Run `/design new-feature [name]` first, then `/design verify new-feature [name]`, then re-run `/feature [name]`." This prevents the soft-condition skip from `/new-feature` Step 5 — Frontend agent will not be dispatched without design handoff in place.

If any check fails: report to human, do not dispatch.

## Step 1 — Backend

Launch Backend Developer subagent (foreground):

```
Task: Feature [name] — Backend

Read:
- .cursor/agents/backend-developer.md (your full instructions)
- agent-workspace/ACTIVE_CONTEXT.md
- artifacts/docs/tech-spec.md
- artifacts/plans/build-plan.md — read the [name] feature context package specifically

Mode: Feature
Build the backend for the [name] feature only — migration, RLS, data hooks, Edge Functions (if needed).
Most features are client → RLS direct and need no Edge Functions.
Signal completion when feat([name]): backend complete is committed.
```

Wait for `feat([name]): backend complete` commit before proceeding.

## Step 2 — Frontend

Launch Frontend Developer subagent (foreground):

```
Task: Feature [name] — Frontend

Read:
- .cursor/agents/frontend-developer.md (your full instructions)
- .cursor/rules/copy-rules.mdc (copy formula, quality test — enforce on all copy)
- agent-workspace/ACTIVE_CONTEXT.md
- artifacts/plans/build-plan.md — read the [name] feature context package specifically
- artifacts/docs/screen-specs-[app]-v1.md — screens for this feature only (metadata: interaction flows, dopamine moment flags, production-ready copy slots, credit costs)
- artifacts/docs/design-system-spec.md
- artifacts/docs/emotional-design-system.md — read §6 if any screen has a dopamine moment flag (D1–D4)

Mode: Feature
For each screen: COPY the screen file from src/design-handoff/screens/ directly into the route file. Then apply targeted str_replace edits per frontend-design.mdc (fix imports, swap mock data → Supabase queries, swap mock auth → useAuth). Do NOT rewrite any handoff file from scratch — 90% of the adapter's handoff stays untouched.
- Implement interaction flows exactly as specified in screen spec metadata
- Copy slots are production-ready — use verbatim
- Add loading/error/empty states below existing JSX (the adapter's handoff output only has happy path)
- Every Tailwind class, animation, and layout decision from the handoff must be preserved exactly

Mutation Patterns (mandatory):
- Every useMutation must invalidate ALL affected query keys in onSuccess. Over-invalidate when in doubt.
- Optimistic UI for user-facing actions (toggle, add, submit) — update cache in onMutate, rollback in onError, refetch in onSettled.
- NO optimistic UI for credit deductions or payment actions — wait for server confirmation.
- See frontend-data.mdc "Mutation Cache Invalidation" and frontend.mdc "Common Agent Mistakes" for full patterns.

Wiring Map (mandatory):
- The build-plan's [name] context package contains a Wiring Map (from tech-spec §10b). It is the binding contract for this feature.
- Every hook, mutation, and Edge Function call you build must match the Wiring Map exactly — same hook name, same query key, same invalidation set, same Edge Function name and body shape.
- If the Wiring Map is wrong or missing, escalate to Tech Lead with NEEDS_CONTEXT — do not invent bindings.

Wire-check gate (mandatory before signaling done):
- After committing screens, run /wire-check [name] and read artifacts/qa-reports/wire-check-[name]-[date].md.
- BLOCKING findings → fix all before signaling. Do not commit "done" with mock data still in active routes, missing invalidations, or orphan Edge Function calls.
- WARN findings → annotate each in the report with a one-line justification, then signal.

Signal completion when feat([name]): screens complete is committed AND /wire-check report is PASS (or PASS-with-annotated-WARNs).
```

Wait for `feat([name]): screens complete` commit before proceeding.

## Step 2b — Mobile (mode ≠ pwa only)

If deployment mode is `native` or `pwa-then-native` Phase B, launch Mobile Developer subagent:

```
Task: Feature [name] — Mobile Screens

Read:
- .cursor/agents/mobile-developer.md (your full instructions)
- .cursor/rules/mobile.mdc (prohibitions + NativeWind rules — read FIRST)
- .cursor/rules/copy-rules.mdc (copy quality test — enforce on all copy)
- agent-workspace/ACTIVE_CONTEXT.md
- artifacts/plans/build-plan.md — read the [name] feature context package
- artifacts/docs/screen-specs-[app]-v1.md — screens for this feature (Mobile Navigation metadata)
- artifacts/docs/design-reference/ — .tsx files for screens in this feature (from the canonical handoff)

Mode: Feature
For each screen: run 3-phase hybrid translation from the canonical handoff's web TSX.
  Phase A: Extract types, mock data, copy strings → shared/
  Phase B: Element swaps, class filtering, Radix→@rn-primitives
  Phase C: Navigation, scroll, keyboard, safe area, haptics
Add loading/error/empty states. Wire TanStack Query hooks from shared/hooks/.
Copy slots are production-ready — use verbatim.

Signal completion when feat([name]): mobile screens complete is committed.
```

For `native` mode: Step 2 (web Frontend) builds landing page only. Step 2b builds all app screens.
For `pwa-then-native` Phase B: skip Step 2 entirely — web screens already exist from Phase A.

Wait for mobile commit before proceeding to QA.

## Step 3 — QA

Launch QA Agent subagent (foreground):

```
Task: Feature [name] — QA

Read:
- .cursor/agents/qa-agent.md (your full instructions)
- .cursor/rules/copy-rules.mdc (copy quality test — validate all screen copy)
- agent-workspace/ACTIVE_CONTEXT.md
- artifacts/docs/tech-spec.md
- artifacts/plans/build-plan.md — read the [name] acceptance criteria specifically
- artifacts/docs/screen-specs-[app]-v1.md — metadata for this feature's screens
- artifacts/docs/emotional-design-system.md — §6 dopamine specs if any screen has a D1–D4 flag

Mode: Feature
Run Pass 0 (wiring smoke test via /wire-check [name]) FIRST. If Pass 0 BLOCKs, halt and signal BLOCKING — do not run Passes 1–5 on a feature that isn't wired.
If Pass 0 passes: run all 5 verification passes (Visual Fidelity, Data & Performance, Security & RLS, Interaction Flows with real data round-trip, Build & Test).
After all passes: run the adversarial cross-check to strip false positives.
Signal PASS (Pass 0 + all 5 clean) or BLOCKING (items grouped by pass number).
```

## After completion

**If PASS:**
1. Update `artifacts/plans/project-plan.md` — mark feature complete
2. Update `agent-workspace/ACTIVE_CONTEXT.md`
3. Report to human: "Feature [name] complete ✓. [Next wave features / All Wave N done]"

**If BLOCKING:**
1. Create `artifacts/issues/[feature-name]-[short-description].md`
2. Report to human with blocking list
3. After fix: re-run Step 3 (QA only)
