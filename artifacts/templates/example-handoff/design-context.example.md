# Design Context — Notebook (example)

This is the **example** populated form of `artifacts/docs/design-context.md` for a notes-taking app called Notebook. It illustrates what "good" looks like when an adapter produces a canonical handoff. Every section below is populated with realistic content so reviewers can compare their own handoff output against a known-complete example.

Structure matches `artifacts/docs/handoff-contract.md` §Design context document — the 9 required H2 sections below are mandatory for every real handoff.

## Brand

- **Voice:** Calm, direct, no-emoji. The persona is a mid-30s knowledge worker who finds most productivity apps too busy.
- **Personality (3 words):** quiet, thoughtful, unhurried
- **Anti-references:** Notion (too many features), Apple Notes (too sparse), Bear (too stylized). Notebook sits between — focused enough for daily use, stylish enough to feel personal.

## Color System

| Token | Hex | OKLCH | Semantic role |
|---|---|---|---|
| primary | `#2565E0` | `oklch(0.55 0.18 240)` | Button primary, focus ring, accent strokes |
| background | `#FDFDFA` | `oklch(0.985 0.005 95)` | page background |
| foreground | `#1E1C18` | `oklch(0.18 0.015 95)` | body text, headings |
| surface | `#FFFFFF` | `oklch(1 0 0)` | Card, Dialog panel |
| muted | `#F4F2ED` | `oklch(0.96 0.005 95)` | Card border, Input border, ghost-button hover |
| muted-foreground | `#6D6A62` | `oklch(0.45 0.01 95)` | secondary text, placeholder |
| success | `#1F8F5A` | `oklch(0.65 0.16 145)` | success badge, save confirmation |
| danger | `#D13D2C` | `oklch(0.6 0.22 25)` | delete button, destructive confirmation |

Dark mode: no (scheduled for v2). Single light palette only.

## Typography

- **Display:** `Fraunces`, Georgia, serif — weight 500–600 — used for h1, h2, CardTitle
- **Body:** `Inter`, system-ui, sans-serif — weight 400–600 — used for body copy, UI labels, button text
- **Modular scale:** 12 / 14 / 16 / 18 / 20 / 24 / 32 / 48 — ratio 1.25. Base body is 16px; buttons are 14px; h1 is 32px.

## Spacing

- **Base unit:** 4px
- **Scale:** 4, 8, 12, 16, 24, 32, 48 (`--space-1` through `--space-8` with gaps at 5 and 7 intentionally omitted). Primary rhythms: 12 (CardHeader margin, body line spacing), 16 (Card default padding, list-item gap), 24 (section gap), 32 (page vertical rhythm).

## Components

| Primitive | Variants | Sizes | Notes |
|---|---|---|---|
| Button | primary, secondary, ghost, danger | sm, md, lg | rounded-md; primary uses `--color-primary`; danger only when destructive |
| Card | (none) | — | padding `--space-4`; border uses `--color-muted`; whole-card is click target in list views |
| CardTitle | (none) | — | `font-display`, `text-lg`, `font-semibold`; paired with CardHeader |
| Input | (none) | — | h-10; full width; focus ring uses `--color-primary` |
| Textarea | (none) | — | min-h 6rem; `resize-y` only (never horizontal); same border/focus as Input |
| Badge | neutral, success, warning, danger | — | text-xs; `tone/15` alpha background + solid foreground |
| Dialog | (none) | — | `aria-modal=true`; ESC closes; backdrop click closes |

**Intentionally not generated (Foundation builds these):** EmptyState, SkeletonCard, ErrorBanner, Sonner/Toast. These are RAD shared components, not part of the handoff.

**Intentionally omitted from MVP:** Avatar, DatePicker, Tooltip, Select, Tabs, Tag multi-select. The persona's three-screen MVP does not need them.

## Interaction Patterns

- **List search:** focus + type triggers filter immediately. No Enter submit, no debounce. Backspace down to empty restores the full list — empty-state copy below the input does not flash.
- **Card click:** entire card surface is the target (not just the title). `role="button"` + `tabIndex={0}` for keyboard access.
- **Detail save:** `Save` button is disabled until title is non-empty after `.trim()`. Body may be empty. No `Cmd+S` keyboard shortcut in MVP.
- **Delete confirmation:** Dialog. ESC closes. Backdrop click closes. Both paths return focus to the previously-focused element.
- **Theme toggle (Settings):** three side-by-side Buttons, not a Select. Click swaps variant immediately; persistence is Foundation's concern.
- **Floating "New note" button:** `position: fixed` bottom-right. 48×48 touch target minimum (`lg` button size). Does not shrink on mobile.
- **Tab order on detail:** Back → Delete → Save → Title → Body. Skip-to-Save is intentional for keyboard-first users.
- **Settings stacking:** three Cards vertically stacked with `space-y-4`. Never combined into one Card — the chunking helps the persona scan.

## Anti-Patterns

Never generate these for Notebook (from EDS §8 + `.cursor/rules/design-system.mdc` Slop Guard):

- No emoji in UI labels, headings, or body copy. Persona finds emoji-in-UI unprofessional.
- No dropdown/Select controls when 3 or fewer options exist — use side-by-side Buttons.
- No tooltips. Persona reads tooltips as noise.
- No modal animations for confirmation prompts — instant open. Fade-ins are considered "trying too hard."
- No relative timestamps ("3 minutes ago"). Use dateline-style ("Saved 2026-04-19").
- No "upgrade first" framing on Settings — Free/Upgrade card sits at the bottom of the stack, visible but not focal.
- No rich-text editor in MVP. Plain-text body only.
- No red for past-due billing — use warning tone. Past-due is recoverable, not destructive.
- No "Sorry / Oops / Hmm" empty-state openings — forbidden in EDS copy formula.

## Copy Rules

- **Language:** English (US). Notebook is US-first; i18n deferred to v2.
- **Forbidden words:** "Simply," "Easy," "Just," "Revolutionize," "Unlock," "Sorry," "Oops," "Hmm." Full list in `.cursor/rules/copy-rules.mdc`.
- **Screen-context rules:** empty states are action-oriented, not apologetic ("No notes match. Clear the search or start a new note." — not "Sorry, no notes found"). Paywall copy is neutral ("Upgrade to Pro for unlimited notes"), not urgent ("Limit reached — upgrade now!"). Reference `.cursor/rules/copy-rules.mdc` §Screen-Context Copy Rules.

## Build Constraints

- **Framework:** React Router v7 (Vite)
- **Styling:** Tailwind v4 with `@theme inline` in `src/app.css` (no `tailwind.config.ts`)
- **Component library:** Radix UI primitives + project-local wrappers in `src/components/ui/`
- **State management:** TanStack Query for server state, `useState` for local, React Context for low-frequency shared (auth, theme)
- **Fonts:** self-hosted `.woff2` in `public/fonts/` via `@font-face` (no CDN `@import`)
- **No:** Zustand, Redux, Jotai, `localStorage` for user state (acceptable for local theme preference in MVP)
