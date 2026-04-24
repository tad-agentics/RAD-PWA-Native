# DESIGN.md Reference Examples

Three full DESIGN.md files from Google Labs, imported as aspirational quality targets. Each is ~200 lines: rich YAML frontmatter with tokens, component index, and multi-section prose.

Use these as calibration for what "good" looks like when:
- Authoring the Phase 2 design brief (how detailed should token lists be?)
- Running `claude-design-adapter` normalization (what prose quality should design-context.md match?)
- Hand-producing `manual-adapter` handoffs (what's the full shape?)
- Reviewing Foundation output (is our design-context.md falling short?)

## Files

| File | Style | Notable elements |
|---|---|---|
| [atmospheric-glass.md](atmospheric-glass.md) | Glassmorphism weather app | Heavy use of rgba/alpha for frosted surfaces, semantic color system (surface/on-surface/outline), Inter typography |
| [paws-and-paths.md](paws-and-paths.md) | Friendly pet care platform | Warm "Golden Retriever" primary + "Sky Walk" secondary, Plus Jakarta Sans, ambient shadow system, mobile-first 4-column grid |
| [totality-festival.md](totality-festival.md) | Dark cosmic music festival | Dual-font (Space Grotesk display + Inter body), glassmorphism on obsidian, ambient glow effects, 12-column editorial grid |

## How to use

### When authoring a design brief

Before running `/phase2`, scan these examples for how token depth, component index richness, and prose detail combine. A good brief gives the adapter enough structure to produce something at this level. A thin brief produces a thin design-context.md.

### When reviewing adapter output

Compare the adapter-produced `src/design-handoff/design-context.md` against these examples side-by-side. If the adapter's YAML is sparser, or the prose sections are stub-like, either:
- The brief was too thin → fix the brief, re-run the adapter
- The adapter is under-producing → escalate to the adapter owner

### When hand-producing a manual handoff

Pick the example closest to your intended aesthetic. Copy its structure as a starting skeleton. Replace tokens with your project's values. Rewrite prose sections to match your brand.

## What these are NOT

- NOT RAD templates — they're external reference. RAD's actual template is `artifacts/templates/design-context-template.md`
- NOT a required shape — the prose sections in these examples (Brand & Style, Colors, Typography, Layout & Spacing, Elevation & Depth, Shapes, Components) follow DESIGN.md v0.1.1 structure. RAD uses a different 9-section structure (Brand, Color System, Typography, Spacing, Components, Interaction Patterns, Anti-Patterns, Copy Rules, Build Constraints) — see `artifacts/docs/handoff-contract.md` v3.1 §Design context document. The YAML frontmatter matches; the prose structure differs.
- NOT what the adapter emits verbatim — adapters produce the YAML frontmatter in this format, then use RAD's 9-section prose structure below

See `NOTICE.md` for attribution and licensing.
