# Design Context — [App Name]

> Template for `design-context.md` — the universal design system doc every adapter produces at the root of `src/design-handoff/`. Structure defined in `artifacts/docs/handoff-contract.md` §Design context document.
>
> Replace every `[placeholder]` with real content. `/design verify` rejects handoffs that still contain template placeholders or empty sections.

## Brand

- **Voice:** [from EDS §1]
- **Personality (3 words):** [word 1], [word 2], [word 3] — from EDS §2
- **Anti-references:** [what this product should NOT look like]

## Color System

| Token | Hex | OKLCH | Semantic role |
|---|---|---|---|
| primary | [hex] | [oklch] | [e.g. CTAs, active states] |
| background | [hex] | [oklch] | [e.g. page background] |
| foreground | [hex] | [oklch] | [e.g. primary text] |
| [add rows as needed per EDS §5] | | | |

Dark mode: [yes | no]. If yes, list dark tokens in a second table.

## Typography

- **Display:** [font family] — [weight range] — used for [headings / hero copy]
- **Body:** [font family] — [weight range] — used for [body copy / UI labels]
- **Modular scale:** [e.g. 12 / 14 / 16 / 20 / 24 / 32 / 48 — ratio 1.25]

## Spacing

- **Base unit:** 4px
- **Scale:** 4, 8, 12, 16, 24, 32, 48, 64, 96

## Components

| Primitive | Variants | Sizes | Notes |
|---|---|---|---|
| Button | primary, secondary, ghost | sm, md, lg | [any usage notes] |
| Card | default, outlined | — | [any usage notes] |
| [≥ 5 primitives for initial builds] | | | |

## Interaction Patterns

- [from EDS §4 — describe interaction semantics: forms, modals, nav, gestures]

## Anti-Patterns

Never generate these (from EDS §8 + `.cursor/rules/design-system.mdc` Slop Guard):

- [e.g. "No gradient backgrounds using purple, violet, or indigo"]
- [e.g. "No 3-column icon-in-circle feature grids"]
- [add project-specific items from EDS §8]

## Copy Rules

- **Language:** [from copy-rules.mdc — e.g. "Vietnamese for all UI copy"]
- **Forbidden words:** [comma-separated list from copy-rules.mdc]
- **Screen-context rules:** [reference copy-rules.mdc §Screen-Context Copy Rules]

## Build Constraints

- **Framework:** React Router v7 (Vite)
- **Styling:** Tailwind v4 with `@theme inline` in `src/app.css` (no `tailwind.config.ts`)
- **Component library:** Radix UI primitives + project-local wrappers in `src/components/ui/`
- **State management:** TanStack Query for server state, `useState` for local, React Context for low-frequency shared
- **Fonts:** self-hosted `.woff2` in `public/fonts/` via `@font-face` (no CDN `@import`)
- **No:** Zustand, Redux, Jotai, `localStorage` for user state
