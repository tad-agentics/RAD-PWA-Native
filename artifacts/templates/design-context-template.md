---
version: alpha
design_md_version: "0.1.1"
name: "[App Name]"
description: "[One-line description of the app's design identity — e.g. 'Warm limestone and ink: a meditative reading interface']"

colors:
  # Core brand tokens (required)
  primary: "[hex]"       # e.g. "#1A1C1E" — CTAs, active states, brand anchor
  secondary: "[hex]"     # e.g. "#6C7278" — borders, metadata, secondary text
  tertiary: "[hex]"      # e.g. "#B8422E" — single accent for emphasis
  neutral: "[hex]"       # e.g. "#F7F5F2" — page background

  # Extended palette (optional — add as needed)
  # Include dark mode tokens only if EDS §5 specifies dark mode support
  # Use flat hex values — NOT token references like {colors.primary}

  # Semantic tokens (required if used in components)
  surface: "[hex]"       # card / modal surface
  on-surface: "[hex]"    # text on surface
  outline: "[hex]"       # borders
  error: "[hex]"         # error states
  success: "[hex]"       # success states

typography:
  # Display tier — headings, hero copy
  display-lg:
    fontFamily: "[font name — e.g. 'Public Sans']"
    fontSize: "[e.g. '48px']"
    fontWeight: "[e.g. '600']"
    lineHeight: "[e.g. '1.1']"
    letterSpacing: "[e.g. '-0.02em']"
  headline-md:
    fontFamily: "[font]"
    fontSize: "[e.g. '24px']"
    fontWeight: "[e.g. '500']"
    lineHeight: "[e.g. '32px']"

  # Body tier — UI labels, body copy
  body-lg:
    fontFamily: "[font]"
    fontSize: "[e.g. '18px']"
    fontWeight: "[e.g. '400']"
    lineHeight: "[e.g. '28px']"
  body-md:
    fontFamily: "[font]"
    fontSize: "[e.g. '16px']"
    fontWeight: "[e.g. '400']"
    lineHeight: "[e.g. '24px']"

  # Label tier — captions, metadata
  label-sm:
    fontFamily: "[font]"
    fontSize: "[e.g. '12px']"
    fontWeight: "[e.g. '600']"
    lineHeight: "[e.g. '16px']"
    letterSpacing: "[e.g. '0.05em']"

rounded:
  sm: "[e.g. '4px']"
  md: "[e.g. '8px']"
  lg: "[e.g. '16px']"
  full: "9999px"

spacing:
  unit: "[e.g. '4px']"       # base unit
  xs: "[e.g. '4px']"
  sm: "[e.g. '8px']"
  md: "[e.g. '16px']"
  lg: "[e.g. '24px']"
  xl: "[e.g. '48px']"

components:
  # Option A: minimal index of primitives in src/design-handoff/components/ui/
  # Each entry names the primitive + references the dominant token it uses.
  # Full styling lives in the TSX file, not here.
  #
  # Format: component-name: primary-token-reference
  # Example:
  #   button-primary: "#B8422E"       # flat hex
  #   card: surface                    # token name (not wrapped — plain string)
  #
  # Agents use this as a fast index of "what primitives exist and what's their dominant color"
  # without reading every TSX file. For detailed styling, read the TSX.

  button-primary: "[token name or hex]"
  button-secondary: "[token name or hex]"
  card: "[token name or hex]"
  input: "[token name or hex]"
  dialog: "[token name or hex]"
  # Add one line per primitive in components/ui/
---

# Design Context — [App Name]

> Template for `design-context.md` — the universal design system doc every adapter produces at the root of `src/design-handoff/`. Structure defined in `artifacts/docs/handoff-contract.md` §Design context document.
>
> Replace every `[placeholder]` with real content. `/design verify` rejects handoffs that still contain template placeholders or empty sections.

## Brand

- **Voice:** [from EDS §1]
- **Personality (3 words):** [word 1], [word 2], [word 3] — from EDS §2
- **Anti-references:** [what this product should NOT look like]

## Color System

> Reference: [artifacts/docs/design-principles/color-and-contrast.md](../docs/design-principles/color-and-contrast.md) — OKLCH color space, palette construction, tinted neutrals, contrast ratios.

| Token | Hex | OKLCH | Semantic role |
|---|---|---|---|
| primary | [hex] | [oklch] | [e.g. CTAs, active states] |
| background | [hex] | [oklch] | [e.g. page background] |
| foreground | [hex] | [oklch] | [e.g. primary text] |
| [add rows as needed per EDS §5] | | | |

Dark mode: [yes | no]. If yes, list dark tokens in a second table.

## Typography

> Reference: [artifacts/docs/design-principles/typography.md](../docs/design-principles/typography.md) — font selection procedure, modular type scales, vertical rhythm, font loading patterns.

- **Display:** [font family] — [weight range] — used for [headings / hero copy]
- **Body:** [font family] — [weight range] — used for [body copy / UI labels]
- **Modular scale:** [e.g. 12 / 14 / 16 / 20 / 24 / 32 / 48 — ratio 1.25]

## Spacing

> Reference: [artifacts/docs/design-principles/spatial-design.md](../docs/design-principles/spatial-design.md) — layout composition, spacing scales, visual rhythm, density.

- **Base unit:** 4px
- **Scale:** 4, 8, 12, 16, 24, 32, 48, 64, 96

## Components

| Primitive | Variants | Sizes | Notes |
|---|---|---|---|
| Button | primary, secondary, ghost | sm, md, lg | [any usage notes] |
| Card | default, outlined | — | [any usage notes] |
| [≥ 5 primitives for initial builds] | | | |

## Interaction Patterns

> Reference: [artifacts/docs/design-principles/interaction-design.md](../docs/design-principles/interaction-design.md) — form patterns, state machines, feedback, loading/error/empty states.

- [from EDS §4 — describe interaction semantics: forms, modals, nav, gestures]

## Anti-Patterns

Never generate these (from EDS §8 + `.cursor/rules/design-system.mdc` Slop Guard):

- [e.g. "No gradient backgrounds using purple, violet, or indigo"]
- [e.g. "No 3-column icon-in-circle feature grids"]
- [add project-specific items from EDS §8]

## Copy Rules

> Reference: [artifacts/docs/design-principles/ux-writing.md](../docs/design-principles/ux-writing.md) — microcopy, labels, error messages, voice/tone consistency.

- **Language:** [from copy-rules.mdc — e.g. "Vietnamese for all UI copy"]
- **Forbidden words:** [comma-separated list from copy-rules.mdc]
- **Screen-context rules:** [reference copy-rules.mdc §Screen-Context Copy Rules]

## Build Constraints

> Reference: [artifacts/docs/design-principles/responsive-design.md](../docs/design-principles/responsive-design.md) — breakpoints, fluid layouts, mobile-first, touch targets. For motion, see [motion-design.md](../docs/design-principles/motion-design.md) (consult only if the feature involves transitions).

- **Framework:** React Router v7 (Vite)
- **Styling:** Tailwind v4 with `@theme inline` in `src/app.css` (no `tailwind.config.ts`)
- **Component library:** Radix UI primitives + project-local wrappers in `src/components/ui/`
- **State management:** TanStack Query for server state, `useState` for local, React Context for low-frequency shared
- **Fonts:** self-hosted `.woff2` in `public/fonts/` via `@font-face` (no CDN `@import`)
- **No:** Zustand, Redux, Jotai, `localStorage` for user state

---

## Using this template

Adapters fill in this template when normalizing tool output during `/design`. Every section must be populated with real content — template placeholders (`[placeholder]`) or empty headings cause `/design verify` to fail per `artifacts/docs/handoff-contract.md` v3 §Design context document.

The reference library at `artifacts/docs/design-principles/` is authoritative for the design principles cited above. When the source tool produces values that contradict the references (e.g. a chroma value that reads garish at that lightness, per `color-and-contrast.md`), the adapter should flag the contradiction in the `notes` field of `handoff-manifest.json` and either correct it or defer to the Tech Lead.

See [artifacts/docs/design-principles/craft.md](../docs/design-principles/craft.md) for the shape-then-build philosophy this template supports.

### DESIGN.md hybrid format (v3.1)

This template follows a hybrid format: YAML frontmatter (DESIGN.md v0.1.1 alpha spec, `@google/design.md@0.1.1`) + RAD's 9-section prose structure. The YAML frontmatter is machine-readable and validates against the DESIGN.md linter (`npx @google/design.md@0.1.1 lint`). The prose sections below capture design context that DESIGN.md's format does not cover (Brand voice, Interaction Patterns, Anti-Patterns, Copy Rules, Build Constraints).

Adapters populate both parts during normalization. The frontmatter must be valid YAML parseable by the DESIGN.md linter; `/design verify` runs the linter and BLOCKS on validation errors.

**Token format:** flat hex values (e.g. `"#1A1C1E"`). Token references (e.g. `"{colors.primary}"`) are supported by the linter but RAD adapters don't emit them — the overhead isn't worth the value at adapter scale. Adapters emit the same hex in multiple places rather than constructing a token graph.

**Components in YAML:** minimal index only. The full styling of each primitive lives in the TSX file at `src/design-handoff/components/ui/[primitive].tsx`. The YAML `components` section gives agents a fast lookup of what primitives exist and their dominant token, without having to crawl the TSX tree. For detailed component styling, read the TSX.

See `artifacts/docs/handoff-contract.md` §Design context document for the full contract.

See `artifacts/docs/design-principles/examples/` for reference DESIGN.md files imported from Google Labs.
