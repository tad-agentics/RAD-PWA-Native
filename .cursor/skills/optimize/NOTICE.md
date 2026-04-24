# NOTICE — optimize skill

This skill is adapted from the Impeccable project's `/optimize` skill.

## Attribution

- **Original project:** Impeccable — Design fluency for AI harnesses
- **Source:** https://github.com/pbakaus/impeccable
- **Website:** https://impeccable.style
- **Upstream version imported:** 2.1.1
- **Upstream path:** `.cursor/skills/optimize/SKILL.md`
- **License:** Apache License, Version 2.0
- **Import date:** 2026-04-24

## License

Apache License, Version 2.0. Full text: http://www.apache.org/licenses/LICENSE-2.0

## Modifications

This skill has been adapted from the upstream version to:

1. Remove `/impeccable teach` and `/impeccable` invocation requirements; anchor in RAD's EDS, design-principles library, and RAD-specific performance baseline
2. **Scope change:** Upstream `/optimize` suggests fixes directly. RAD's `/optimize` flags issues with severity + remediation path routing (mechanical fix in scope / new-feature loop / framework config / defer), same discipline as `/harden`. This preserves the 90% untouched rule — agents don't creatively rework performance during integration.
3. Add **RAD perf baseline table** — mid-tier Android 4G targets, query-caching hygiene, Reanimated/transform-only animation rules — so findings measure against RAD's actual operating context, not generic thresholds
4. Cross-reference `.cursor/skills/caching-strategies/SKILL.md` — many perf issues in RAD are TanStack Query hygiene issues, not code issues
5. Add RAD integration — pipeline entry points, output location, relationship to other QA skills
6. Pin adapter semver (`optimize-rad@1.0.0`) separately from upstream (`impeccable/optimize@2.1.1`)

The diagnostic methodology (5 dimensions — loading, rendering, animations, images, bundle) and specific patterns (layout thrashing detection, animation property choices, lazy loading, tree-shaking) are preserved. The adaptation layers RAD's context and routing over upstream's diagnostic engine.

## Upstream sync

See `artifacts/docs/design-principles/NOTICE.md` §Upstream updates.
