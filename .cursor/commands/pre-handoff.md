# /pre-handoff

Dispatch the QA Agent for the pre-handoff safety audit.
Runs after all feature waves pass QA and the visual fidelity audit is complete.

## Pre-flight checks

Before dispatching, confirm:
- [ ] All features in `artifacts/plans/project-plan.md` are marked complete
- [ ] Visual fidelity audit complete — all BLOCKING items fixed (run `/visual-audit [url]` if not done)
- [ ] Dogfooding complete — `artifacts/qa-reports/dogfood-report.md` exists with 0 BLOCKING findings (run `/dogfood` if not done)
- [ ] `artifacts/docs/changelog.md` — 0 BLOCKING items
- [ ] `artifacts/issues/` — 0 open BLOCKING issues
- [ ] `npm run build` passes on current state

If any check fails: report to human, do not dispatch.

## Dispatch

Launch QA Agent subagent (foreground):

```
Task: Pre-Handoff Safety Audit

Read:
- .cursor/agents/qa-agent.md (your full instructions)
- .cursor/skills/security-audit/SKILL.md (security audit instructions)
- .cursor/rules/copy-rules.mdc (copy quality test for compliance check)
- agent-workspace/ACTIVE_CONTEXT.md
- artifacts/docs/tech-spec.md
- artifacts/docs/screen-specs-[app]-v1.md (interaction flows, credit costs for paywall gate integrity check)
- artifacts/docs/emotional-design-system.md (§6 dopamine specs for fidelity check)
- artifacts/docs/changelog.md

Mode: Pre-Handoff
Run the full pre-handoff audit: security audit (security-audit SKILL.md) + SPA-specific checks defined in your agent file's Pre-Handoff Mode.
Then run a final adversarial cross-check: challenge each finding — is it a real bug or a false positive?
Apply AUTO-FIX items directly. Escalate BLOCKING items to Tech Lead.
Signal completion when test: pre-handoff review complete is committed.
```

## Mobile pre-handoff additions (mode ≠ pwa)

If deployment mode is `native` or `pwa-then-native`, add these checks to the QA dispatch:

```
Additional mobile checks (append to Pre-Handoff audit):

1. Accessibility audit:
   - VoiceOver (iOS): navigate every screen with screen reader. Every interactive element must announce its role and label.
   - TalkBack (Android): same pass. Flag any silent or mis-labeled elements as BLOCKING.
   
2. Deep links:
   - Verify scheme://[path] opens the correct screen for every route in Expo Router
   - Verify auth-guarded deep links redirect to login then forward after auth
   
3. Push notifications (if §7c specifies push):
   - Verify token registration on fresh install
   - Verify notification received when sent via Expo Push Service test
   - Verify tap on notification navigates to correct screen
   
4. Biometrics (if §7c specifies local-authentication):
   - Verify Face ID / fingerprint prompt appears at configured trigger
   - Verify fallback to PIN/password works
   
5. Cross-platform rendering:
   - Every screen checked on both iOS Simulator and Android Emulator
   - Shadows, fonts, keyboard behavior, status bar verified on both
   
6. Offline behavior:
   - Disable network. App shows cached data or graceful error — no white screen or crash.
   - Re-enable network. Data refreshes automatically.
```

---

## Pass 6 — Technical Quality Audit (optional, recommended)

Run `/audit` on the full app or specific feature surfaces. Generates a scored report at `artifacts/qa-reports/audit-[YYYY-MM-DD]-[scope].md` across 5 dimensions (a11y, performance, theming, responsive, anti-patterns) with P0-P3 severity.

**When to skip:** simple features where `/visual-audit` already passed cleanly AND the feature surface is small (<3 screens). Otherwise run it.

**Tech Lead reviews findings and decides:** fix now (if P0/P1) / defer (P2/P3) / document as known limitation.

See `.cursor/skills/audit/SKILL.md`.

## Pass 7 — UX Design Critique (optional, recommended for user-facing flows)

Run `/critique` on the primary user flows. Generates persona-based assessments + Nielsen heuristics scoring at `artifacts/qa-reports/critique-[YYYY-MM-DD]-[scope].md`.

**When to run:** every release with new user-facing surfaces. Skip for backend-only changes or internal tooling.

**Tech Lead reviews and decides:** adjust before ship / accept findings / route to new-feature loop if the gap requires design-layer rework.

See `.cursor/skills/critique/SKILL.md`.

## Pass 8 — Production-Readiness Hardening (optional, recommended)

Run `/harden` on the full app. Generates a gap report at `artifacts/qa-reports/harden-[YYYY-MM-DD]-[scope].md` covering text overflow, error states, empty states, onboarding, i18n, edge cases.

**When to skip:** regen-only releases where no new flows were added.

**Remediation paths** (from the skill):

- Mechanical fix in scope (trivial, no design judgment) — fix now
- New-feature loop (requires new UI states / copy / flows) — route back through `/design new-feature [gap-name]`
- Document + defer

See `.cursor/skills/harden/SKILL.md`.

## Pass 9 — Performance Diagnostics (optional, recommended for high-traffic launches)

Run `/optimize` on the primary screens + critical user paths. Generates measured findings at `artifacts/qa-reports/optimize-[YYYY-MM-DD]-[scope].md` vs RAD's perf baseline (LCP < 2.5s on 4G, < 200KB initial JS, etc.).

**When to skip:** internal features with low traffic, or features where `/audit` perf score was already 3-4.

**Remediation paths:**

- Mechanical fix (lazy loading, memoization, Reanimated swap) — fix now
- Design-layer rework (image art direction, loading state design) — new-feature loop
- Framework config (Vite, Router prerender) — Tech Lead owns
- Defer

See `.cursor/skills/optimize/SKILL.md`.

---

## Pass execution order and gating

Passes 1–5 are RAD-native and BLOCKING — `/pre-handoff` fails if any pass fails.

Passes 6–9 are Impeccable-imported and ADVISORY — findings route to Tech Lead triage per each skill's remediation-path guidance. A P0 finding in Pass 6-9 typically blocks ship; P1-P3 are judgment calls.

**Recommended sequence for a major launch:**
1–5 (blocking) → 6 → 7 → 8 → 9 → Tech Lead triage all findings → ship or remediate.

**Recommended sequence for a small feature addition:**
1–5 (blocking) → 6 (if >3 screens changed) → Tech Lead triage → ship.

## After completion

**If clean (0 BLOCKING items):**
1. Update project-plan.md — mark pre-handoff complete
2. Present to human:

```
Pre-handoff audit complete. No blocking issues.

AUTO-FIX items applied: [N]
Informational findings logged: [N]

Ready for production deploy. Run /deploy when ready.
```

**If BLOCKING items found:**
1. Present findings to human
2. Create issues in `artifacts/issues/`
3. After fixes: re-run `/pre-handoff`
