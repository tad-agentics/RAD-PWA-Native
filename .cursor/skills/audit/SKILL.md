---
name: audit
description: Run technical quality checks across accessibility, performance, theming, responsive design, and anti-patterns. Generates a scored P0-P3 report with an actionable remediation plan. Runs as part of /pre-handoff, or invoked standalone when the Tech Lead wants a quality check on a specific feature or screen. Complements /visual-audit (which is fidelity-focused) by checking whether the shipped result is actually production-quality, not just visually matching the handoff.
disable-model-invocation: true
user-invocable: true
argument-hint: "[area (feature, page, component...)]"
version: audit-rad@1.0.0
upstream: impeccable/audit@2.1.1
license: Apache 2.0 — see NOTICE.md
---

## MANDATORY PREPARATION

Before running this skill, confirm:

- `artifacts/docs/design-context.md` exists (produced by the active adapter during `/foundation` — see `artifacts/docs/handoff-contract.md` (v3 or v3.1) §Design context document)
- `artifacts/docs/design-principles/` exists and contains the 9 reference files (typography, color-and-contrast, spatial-design, motion-design, interaction-design, responsive-design, ux-writing, craft, extract)

If either is missing, halt and report. Do not audit without context — a "technical" audit that ignores the project's design principles will flag false positives and miss real issues.

When auditing, cross-reference findings against `artifacts/docs/design-principles/` for the relevant dimension. Example: an accessibility contrast finding should cite `color-and-contrast.md` §Contrast. This anchors findings in the project's established design principles, not generic heuristics.

---

Run systematic **technical** quality checks and generate a comprehensive report. Don't fix issues — document them for other commands to address.

This is a code-level audit, not a design critique. Check what's measurable and verifiable in the implementation.

## Diagnostic Scan

Run comprehensive checks across 5 dimensions. Score each dimension 0-4 using the criteria below.

### 1. Accessibility (A11y)

**Check for**:
- **Contrast issues**: Text contrast ratios < 4.5:1 (or 7:1 for AAA)
- **Missing ARIA**: Interactive elements without proper roles, labels, or states
- **Keyboard navigation**: Missing focus indicators, illogical tab order, keyboard traps
- **Semantic HTML**: Improper heading hierarchy, missing landmarks, divs instead of buttons
- **Alt text**: Missing or poor image descriptions
- **Form issues**: Inputs without labels, poor error messaging, missing required indicators

**Score 0-4**: 0=Inaccessible (fails WCAG A), 1=Major gaps (few ARIA labels, no keyboard nav), 2=Partial (some a11y effort, significant gaps), 3=Good (WCAG AA mostly met, minor gaps), 4=Excellent (WCAG AA fully met, approaches AAA)

### 2. Performance

**Check for**:
- **Layout thrashing**: Reading/writing layout properties in loops
- **Expensive animations**: Animating layout properties (width, height, top, left) instead of transform/opacity
- **Missing optimization**: Images without lazy loading, unoptimized assets, missing will-change
- **Bundle size**: Unnecessary imports, unused dependencies
- **Render performance**: Unnecessary re-renders, missing memoization

**Score 0-4**: 0=Severe issues (layout thrash, unoptimized everything), 1=Major problems (no lazy loading, expensive animations), 2=Partial (some optimization, gaps remain), 3=Good (mostly optimized, minor improvements possible), 4=Excellent (fast, lean, well-optimized)

### 3. Theming

**Check for**:
- **Hard-coded colors**: Colors not using design tokens
- **Broken dark mode**: Missing dark mode variants, poor contrast in dark theme
- **Inconsistent tokens**: Using wrong tokens, mixing token types
- **Theme switching issues**: Values that don't update on theme change

**Score 0-4**: 0=No theming (hard-coded everything), 1=Minimal tokens (mostly hard-coded), 2=Partial (tokens exist but inconsistently used), 3=Good (tokens used, minor hard-coded values), 4=Excellent (full token system, dark mode works perfectly)

### 4. Responsive Design

**Check for**:
- **Fixed widths**: Hard-coded widths that break on mobile
- **Touch targets**: Interactive elements < 44x44px
- **Horizontal scroll**: Content overflow on narrow viewports
- **Text scaling**: Layouts that break when text size increases
- **Missing breakpoints**: No mobile/tablet variants

**Score 0-4**: 0=Desktop-only (breaks on mobile), 1=Major issues (some breakpoints, many failures), 2=Partial (works on mobile, rough edges), 3=Good (responsive, minor touch target or overflow issues), 4=Excellent (fluid, all viewports, proper touch targets)

### 5. Anti-Patterns (CRITICAL)

Check against RAD's anti-pattern rules: the `artifacts/docs/design-principles/` reference files call out slop tells per dimension, and `.cursor/rules/design-system.mdc` §AI Slop Guard enumerates RAD-specific DON'Ts (AI color palette, gradient text, glassmorphism, hero metrics, card grids, generic fonts, gray on color, nested cards, bounce easing, redundant copy).

**Score 0-4**: 0=AI slop gallery (5+ tells), 1=Heavy AI aesthetic (3-4 tells), 2=Some tells (1-2 noticeable), 3=Mostly clean (subtle issues only), 4=No AI tells (distinctive, intentional design)

## Generate Report

### Audit Health Score

| # | Dimension | Score | Key Finding |
|---|-----------|-------|-------------|
| 1 | Accessibility | ? | [most critical a11y issue or "--"] |
| 2 | Performance | ? | |
| 3 | Responsive Design | ? | |
| 4 | Theming | ? | |
| 5 | Anti-Patterns | ? | |
| **Total** | | **??/20** | **[Rating band]** |

**Rating bands**: 18-20 Excellent (minor polish), 14-17 Good (address weak dimensions), 10-13 Acceptable (significant work needed), 6-9 Poor (major overhaul), 0-5 Critical (fundamental issues)

### Anti-Patterns Verdict
**Start here.** Pass/fail: Does this look AI-generated? List specific tells. Be brutally honest.

### Executive Summary
- Audit Health Score: **??/20** ([rating band])
- Total issues found (count by severity: P0/P1/P2/P3)
- Top 3-5 critical issues
- Recommended next steps

### Detailed Findings by Severity

Tag every issue with **P0-P3 severity**:
- **P0 Blocking**: Prevents task completion — fix immediately
- **P1 Major**: Significant difficulty or WCAG AA violation — fix before release
- **P2 Minor**: Annoyance, workaround exists — fix in next pass
- **P3 Polish**: Nice-to-fix, no real user impact — fix if time permits

For each issue, document:
- **[P?] Issue name**
- **Location**: Component, file, line
- **Category**: Accessibility / Performance / Theming / Responsive / Anti-Pattern
- **Impact**: How it affects users
- **WCAG/Standard**: Which standard it violates (if applicable)
- **Reference cited**: Which `artifacts/docs/design-principles/` file supports the finding (e.g. `color-and-contrast.md` §Contrast)
- **Recommendation**: How to fix it
- **Suggested owner**: Which RAD agent should pick this up (`frontend-developer` for UI/styling/a11y; `backend-developer` for API/data; `qa-agent` for verification-only fixes). The Tech Lead routes the fix.

### Patterns & Systemic Issues

Identify recurring problems that indicate systemic gaps rather than one-off mistakes:
- "Hard-coded colors appear in 15+ components, should use design tokens"
- "Touch targets consistently too small (<44px) throughout mobile experience"

### Positive Findings

Note what's working well — good practices to maintain and replicate.

## Recommended Actions

List recommended fixes in priority order (P0 first, then P1, then P2):

1. **[P?] [Fix title]** — Brief description. Owner: [agent]. Blast radius: [N files / single component / system-wide].
2. **[P?] [Fix title]** — Brief description. Owner: [agent]. Blast radius: [...].

**Rules**: Be specific and actionable. Map each finding to a concrete change, not a generic "improve X". The Tech Lead dispatches the appropriate agent for each fix.

After presenting the summary, tell the Tech Lead:

> You can dispatch these fixes one at a time (surgical), all at once (broad refactor), or bundle P0+P1 for pre-handoff and defer P2+P3 to a follow-up wave.
>
> Re-run `/audit [scope]` after fixes to see the score improve.

**IMPORTANT**: Be thorough but actionable. Too many P3 issues creates noise. Focus on what actually matters.

**NEVER**:
- Report issues without explaining impact (why does this matter?)
- Provide generic recommendations (be specific and actionable)
- Skip positive findings (celebrate what works)
- Forget to prioritize (everything can't be P0)
- Report false positives without verification

Remember: You're a technical quality auditor. Document systematically, prioritize ruthlessly, cite specific code locations, and provide clear paths to improvement.

---

## RAD integration

This skill runs at two entry points:

### Entry point 1 — `/pre-handoff` (automatic)
When `/pre-handoff` executes, it calls this skill as Pass 6 after the five existing QA passes. The Tech Lead reviews the scored report before approving handoff. See `.cursor/commands/pre-handoff.md` §Pass 6.

### Entry point 2 — standalone (ad hoc)
The Tech Lead can invoke `/audit [feature-or-screen]` anytime during development to get a quality read on a specific surface. Useful during Feature Mode when a dogfood session flags something that "feels off" but isn't a fidelity bug.

## Output location

The scored report gets written to:
- `artifacts/qa-reports/audit-[YYYY-MM-DD]-[scope].md`

Where `[scope]` is either the feature name (for targeted audits) or `full-app` (for pre-handoff runs). The report follows the P0-P3 severity format in this skill's instructions.

## Relationship to other QA skills

| Skill | Purpose | Runs |
|---|---|---|
| `/audit` (this skill) | Technical quality across a11y, perf, theming, responsive, anti-patterns | `/pre-handoff` Pass 6, or standalone |
| `/critique` | UX design review with persona sub-agents + Nielsen heuristics | `/pre-handoff` Pass 7, or standalone |
| `/harden` | Production-readiness — error states, empty states, i18n, overflow | `/pre-handoff` Pass 8, or standalone |
| `/optimize` | UI performance diagnostics — bundle, rendering, animations | `/pre-handoff` Pass 9, or standalone |
| `/visual-audit` | Fidelity check — does the shipped result match the handoff? | End of every Feature Mode run |

The first four are imported from Impeccable (see NOTICE.md). `/visual-audit` is RAD-native.

---

## Attribution

This skill is adapted from Impeccable's `/audit`. See `NOTICE.md` in this directory for upstream attribution and license terms (Apache 2.0).
