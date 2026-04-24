# NOTICE — DESIGN.md example files

The three example files in this directory (`atmospheric-glass.md`, `paws-and-paths.md`, `totality-festival.md`) are copied from the Google Labs DESIGN.md project.

## Attribution

- **Original project:** DESIGN.md — A format specification for describing a visual identity to coding agents
- **Source:** https://github.com/google-labs-code/design.md
- **Upstream version imported:** v0.1.1 (alpha)
- **Upstream path:** `examples/[example-name]/DESIGN.md`
- **License:** Apache License, Version 2.0 — Copyright 2026 Google LLC
- **Import date:** 2026-04-24

## License

The imported content is licensed under the Apache License, Version 2.0. A copy of the license is available at:

http://www.apache.org/licenses/LICENSE-2.0

## Modifications

The example files have been lightly modified from the upstream versions:

1. Renamed from `DESIGN.md` (singular, in subdirectory) to `[example-name].md` (distinctive, flat) — matches RAD's `artifacts/docs/design-principles/examples/` structure
2. A one-line provenance header prepended above the YAML frontmatter: `<!-- Reference example from Google Labs DESIGN.md v0.1.1. See NOTICE.md. -->`
3. No content changes to the YAML tokens or markdown prose — these are the authoritative reference examples

The upstream versions also ship `tailwind.config.js` (Tailwind v3 theme) and `design_tokens.json` (W3C DTCG format) alongside each DESIGN.md. Those are **not imported** because:
- RAD uses Tailwind v4 `@theme inline` (no JS config)
- W3C DTCG JSON duplicates information already in the YAML frontmatter

Only the DESIGN.md prose files are imported here.

## Upstream sync

See `artifacts/docs/design-principles/NOTICE.md` §Upstream updates for the general process. For these example files specifically, check the DESIGN.md repo examples/ directory for new or updated examples each upstream release; copy them in with the same adaptation (rename + provenance header).
