# NOTICE — critique skill

This skill is adapted from the Impeccable project's `/critique` skill.

## Attribution

- **Original project:** Impeccable — Design fluency for AI harnesses
- **Source:** https://github.com/pbakaus/impeccable
- **Website:** https://impeccable.style
- **Upstream version imported:** 2.1.1
- **Upstream path:** `.cursor/skills/critique/`
- **License:** Apache License, Version 2.0
- **Import date:** 2026-04-24

## License

The imported content is licensed under the Apache License, Version 2.0. A copy of the license is available at:

http://www.apache.org/licenses/LICENSE-2.0

## Modifications

This skill has been adapted from the upstream version to:

1. Remove `/impeccable teach` and `/impeccable` invocation requirements
2. Anchor critique findings in RAD's EDS and design-principles library, not Impeccable's `.impeccable.md`
3. Add RAD-specific integration — pipeline entry points, output location, when to invoke standalone
4. Pin adapter semver (`critique-rad@1.0.0`) separately from upstream (`impeccable/critique@2.1.1`)

The methodology (parallel persona sub-agents, Nielsen heuristics scoring, cognitive load analysis, persona and heuristics reference files) is preserved. This is a thin adaptation layer.

## Reference files

The `reference/` subdirectory (personas.md, cognitive-load.md, heuristics-scoring.md) is imported with light-touch adaptation — only cross-references are updated. The methodology content is verbatim from upstream.

## Upstream sync

See `artifacts/docs/design-principles/NOTICE.md` §Upstream updates for the process.
