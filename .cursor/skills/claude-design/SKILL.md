---
name: claude-design
description: Human-driver guide for Claude Design — prompting patterns, handoff export, iterative regen for /new-feature, and drift control. Read this before running Claude Design in any phase. Pairs with artifacts/docs/handoff-contract.md.
disable-model-invocation: true
---

# Claude Design — Human Driver Guide

Claude Design is the visual design step in RAD. A human drives it. This file documents how to prompt it well, what to export, and how to re-enter it for `/new-feature` without breaking the existing handoff.

**Agents do not run Claude Design.** The Tech Lead and subagents read the exported handoff bundle from `src/design-handoff/` (initial build) or `src/design-handoff/new-feature-[name]/` (incremental). See `artifacts/docs/handoff-contract.md` for the required file shape.

---

## When You Enter Claude Design

| Trigger | Input brief | Output location |
|---|---|---|
| Initial build, after `/phase2` | `artifacts/docs/claude-design-brief.md` | `src/design-handoff/` |
| `/new-feature` requiring new screens | Feature doc + existing codebase | `src/design-handoff/new-feature-[name]/` |
| `/visual-audit` flagged drift | Spot-regen for the broken screen only | `src/design-handoff/regen-[screen]/` |

Claude Design can read your existing codebase. After Foundation, always point it at the repo so it matches the already-integrated design system instead of reinventing tokens.

---

## Prompting Patterns

### 1. Initial Build

Paste `artifacts/docs/claude-design-brief.md` verbatim. Then add:

```
Generate a complete working React + Tailwind app covering every screen in the brief.
Use hardcoded mock data for all lists, forms, and detail views.
Export a handoff bundle matching artifacts/docs/handoff-contract.md.
```

Do not ask Claude Design to skip any screen. Skipped screens become invented later by the Frontend agent — that is where drift starts.

### 2. Incremental (`/new-feature`)

Point Claude Design at the repo first:

```
Read src/components/ui/, src/app.css, and src/routes/_app/ to match the existing
design system exactly. Do not regenerate UI primitives — use the ones already in
src/components/ui/. Use the same typography scale, spacing, and brand tokens.
```

Then paste the feature doc's frontend scope and acceptance criteria. Ask only for the new screens. Export to `src/design-handoff/new-feature-[name]/` — never overwrite the initial `src/design-handoff/`.

### 2b. Native-targeted brief (HIGH-risk screens only)

When the mobile-developer risk queue flags a screen as HIGH (grid-heavy layout, motion sequences — do not use framer-motion on native — rich interactions), ask Claude Design to emit RN-shaped output directly instead of translating from web TSX:

```
Generate this screen for React Native + Expo Router + NativeWind.
- Use View / Pressable / Text / TextInput / FlashList — no DOM primitives.
- Do not use framer-motion; use Animated or Reanimated if motion is needed.
- Match the existing NativeWind tokens in mobile/global.css.
- Output a single file at [screen-name].tsx. Do not invent new UI primitives — use the existing ones in mobile/src/components/.
```

Export to `artifacts/docs/design-reference/native/[screen-name]/`. The mobile-developer's translation queue uses this as the source for that screen instead of the web TSX.

Use only when HIGH-risk — each extra Claude Design run burns time and cost. If more than 3 HIGH-risk screens appear, escalate the whole native build back to the Tech Lead.

### 3. Drift Regen (`/visual-audit`)

When QA flags a screen as drifted from the original Claude Design output:

```
Regenerate only [screen name] matching the design tokens in src/app.css
and the UI primitives in src/components/ui/. Preserve the mock data shape
currently in src/design-handoff/[screen file].
```

Export to `src/design-handoff/regen-[screen]/`. The Frontend agent diffs and re-copies the affected file.

---

## Anti-Patterns (do not do)

- **Do not let Claude Design rewrite `src/components/ui/`** after Foundation — primitives are locked once copied.
- **Do not accept new brand tokens** mid-build. If Claude Design invents new colors/spacing on a re-run, reject the export and re-prompt with the existing token list from `src/app.css`.
- **Do not export directly over `src/design-handoff/`** after Foundation. Use the suffixed folders above.
- **Do not ask for backend logic** — Claude Design produces UI + mock data only. Supabase wiring is the Frontend agent's job.
- **Do not skip the brief** and ad-hoc prompt from the northstar. The brief encodes anti-bloat rules and copy direction the agents expect downstream.

---

## Export Checklist

Before leaving Claude Design:

- [ ] Every screen in `artifacts/docs/screen-specs-[app]-v1.md` has a file in the export
- [ ] `App.tsx` or `routes.tsx` wires every screen (navigation is resolvable)
- [ ] `theme.css` is present with CSS custom properties + `@theme inline`
- [ ] `components/ui/` has every primitive referenced by screens
- [ ] Mock data is inline or colocated — no fetch calls, no network requests
- [ ] No loose `globals.css`, no Next.js-specific files (`app/`, `page.tsx`)

Full required shape: `artifacts/docs/handoff-contract.md`.

---

## Logging Usage (for the studio)

After each Claude Design session, append to `artifacts/docs/claude-design-log.md`:

```
## [YYYY-MM-DD] [phase/feature]
- Prompt iterations: [count]
- Screens generated: [count]
- Rework reason (if any): [short note]
- What worked in the prompt: [short note]
```

This is the studio's compounding asset — successful prompt patterns carry across apps. The Product Designer reviews this log when writing the next brief.

---

## Failure Modes + Escalation

| Symptom | Likely cause | Fix |
|---|---|---|
| Handoff missing `components/ui/` | Claude Design inlined primitives | Re-prompt: "Extract shared components into `components/ui/`" |
| Primitives duplicated across screens | Same as above | Same fix |
| Brand tokens invented | Brief lacked explicit token values | Add token values to brief §Brand Context, re-run |
| Mock data inconsistent across screens (e.g., different user fields) | No single source in the brief | Add a "Mock Entities" section to the brief listing entity shapes, re-run |
| Screen missing from export | Brief was too long or screen underspecified | Split the brief, run per-wave |

If 3 iterations don't yield a clean handoff, escalate to the Tech Lead — the brief is likely the problem, not Claude Design.
