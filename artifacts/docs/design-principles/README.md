# Design Reference Library

Deep reference material on design principles across 9 dimensions. Every design brief produced by RAD's Phase 2 / product-designer references these files. The active design adapter consults them when normalizing tool output into `design-context.md`.

This library is adapted from the Impeccable project — see [NOTICE.md](NOTICE.md) for attribution and licensing.

---

## Files

| File | Scope | When to consult |
|---|---|---|
| [typography.md](typography.md) | Type scales, font selection, readability, OpenType features, web font loading | Every project — typography is foundational |
| [color-and-contrast.md](color-and-contrast.md) | OKLCH color, palette construction, contrast, tinted neutrals, semantic colors | Every project — color is foundational |
| [spatial-design.md](spatial-design.md) | Layout, spacing, grid, visual rhythm, density | Every project — layout is foundational |
| [motion-design.md](motion-design.md) | Animation principles, easing, timing, micro-interactions | When the northstar §7 flags motion or the feature involves transitions |
| [interaction-design.md](interaction-design.md) | Form patterns, state machines, feedback, error handling, loading states | Complex interactive features, forms, multi-step flows |
| [responsive-design.md](responsive-design.md) | Breakpoints, fluid layouts, mobile-first, touch targets | Every project — RAD targets mobile-first Vietnamese B2C |
| [ux-writing.md](ux-writing.md) | Microcopy, labels, error messages, voice/tone consistency | Every project — copy is always design |
| [craft.md](craft.md) | Design build flow — shape, load references, iterate visually | Reference for the Phase 2 product-designer and Foundation flow |
| [extract.md](extract.md) | Pulling reusable primitives and tokens into the design system | Post-Foundation when cataloging `src/components/ui/` |

---

## How these integrate with RAD

**Phase 1 (EDS authoring):** The emotional-design-system document references these files by name when documenting brand decisions. For example, EDS §5 Color System cites `color-and-contrast.md` for OKLCH rationale.

**Phase 2 (design brief production):** The product-designer's brief output points the design tool at these references. See `artifacts/docs/design-brief.md` and `.cursor/skills/wireframes/SKILL.md` — the brief's "Recommended References" section enumerates which files to consult.

**Foundation:** When the active design adapter (see `artifacts/design-tool.config.json`) normalizes tool output into `design-context.md`, these files inform the canonical template's population. Content that the tool extracts from its own output gets cross-checked against these references; anything the tool didn't produce falls back to RAD's EDS.

**Agents:** The frontend-developer and mobile-developer agents consult these references when the handoff has gaps (missing interaction states, no motion guidance, no empty-state pattern) to fill in without inventing.

---

## Editing rules

- Substantive design principles (the content) should generally mirror the upstream Impeccable library for parity with community best practice. Bug fixes or obvious improvements are fine — preserve them in the file's change history at the bottom.
- RAD-specific adaptations (cross-references to EDS, Phase 2, design adapters) are expected and documented in NOTICE.md §Modifications.
- Do NOT rewrite these files to match an individual project's style. They are studio-level references.

---

## Reference examples

Full DESIGN.md files from Google Labs (Apache 2.0), imported as aspirational quality targets. See [examples/](examples/) for three complete reference systems: Atmospheric Glass (glassmorphism weather app), Paws & Paths (friendly pet care platform), Totality Festival (dark cosmic music festival).

Each example is ~200 lines of rich YAML tokens + multi-section prose. Use them to calibrate what "good" design-context.md output looks like when reviewing adapter output or authoring briefs.

Attribution in [examples/NOTICE.md](examples/NOTICE.md).

---

## Upstream sync

See [NOTICE.md](NOTICE.md) §Upstream updates for the process to pull newer Impeccable releases into this fork.
