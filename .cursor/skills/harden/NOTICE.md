# NOTICE — harden skill

This skill is adapted from the Impeccable project's `/harden` skill.

## Attribution

- **Original project:** Impeccable — Design fluency for AI harnesses
- **Source:** https://github.com/pbakaus/impeccable
- **Website:** https://impeccable.style
- **Upstream version imported:** 2.1.1
- **Upstream path:** `.cursor/skills/harden/SKILL.md`
- **License:** Apache License, Version 2.0
- **Import date:** 2026-04-24

## License

Apache License, Version 2.0. Full text: http://www.apache.org/licenses/LICENSE-2.0

## Modifications

This skill has been adapted from the upstream version to:

1. Remove `/impeccable teach` and `/impeccable` invocation requirements; anchor in RAD's EDS + design-principles library instead
2. **Scope change — critical:** Upstream `/harden` is prescriptive (it describes how to fix gaps). RAD's `/harden` flags gaps and escalates to the Tech Lead for triage. The frontend-developer does not auto-implement fixes — that would violate RAD's 90% untouched rule (no auto-implement). Missing states / flows / interactions route back through a new-feature loop so the adapter produces them, preserving the design-layer / integration-layer boundary.
3. Add RAD-specific integration — pipeline entry points, output location, gap report format with severity + remediation path triage
4. Pin adapter semver (`harden-rad@1.0.0`) separately from upstream (`impeccable/harden@2.1.1`)

The underlying hardening dimensions (text overflow, i18n, error states, empty states, onboarding, edge cases) and their specific patterns (flex min-width-0, line-clamp, German ~30% expansion, RTL handling, etc.) are preserved verbatim. The adaptation is about **how RAD uses findings**, not **what counts as a finding**.

## Upstream sync

See `artifacts/docs/design-principles/NOTICE.md` §Upstream updates for the process to pull newer Impeccable releases into this fork.
