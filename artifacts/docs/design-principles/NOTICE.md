# NOTICE

The design reference library in this directory (`artifacts/docs/design-principles/`) is adapted from the Impeccable project by Paul Bakaus.

## Attribution

- **Original project:** Impeccable — Design fluency for AI harnesses
- **Source:** https://github.com/pbakaus/impeccable
- **Website:** https://impeccable.style
- **License:** Apache License, Version 2.0
- **Upstream version imported:** 2.1.1
- **Import date:** 2026-04-23

## License

The imported content is licensed under the Apache License, Version 2.0. A copy of the license is available at:

http://www.apache.org/licenses/LICENSE-2.0

## Modifications

Files in this directory have been modified from the original Impeccable source to:
1. Remove or adapt references to Impeccable-specific commands (`/impeccable teach`, `/impeccable craft`, `/shape`, etc.) that do not exist in RAD
2. Reframe cross-references to point at RAD's pipeline (Phase 1 EDS, Phase 2 screen specs, the active design adapter)
3. Integrate with RAD's canonical design handoff contract v3
4. Absorbed UX-writing patterns from Impeccable's `/clarify` skill (upstream v2.1.1) into `.cursor/rules/copy-rules.mdc` §UX Writing Principles. `/clarify` is NOT imported as a standalone skill — its content is rule-shape, not skill-shape. Attribution preserved here.

The modifications are RAD-specific and do not impair the design principles documented in the original Impeccable reference library.

## Upstream updates

This is a fork, not a dependency. Upstream Impeccable releases are not automatically incorporated. To pull upstream improvements:

1. Download the latest Impeccable release from https://impeccable.style or GitHub
2. Compare with this fork's files
3. Manually apply upstream changes, preserving RAD-specific adaptations
4. Update the `Upstream version imported` date above

Impeccable's original frontend-design skill was itself derived from Anthropic's frontend-design skill. Attribution in this NOTICE includes both upstream sources.
