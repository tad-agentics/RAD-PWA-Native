# /phase3

> **Phase 3 is absorbed into the design tool step + Foundation.** This command is not dispatched separately.

The configured design tool (see `artifacts/design-tool.config.json` + the active adapter's SKILL.md) handles visual design — colors, typography, spacing, components. The design system component inventory is produced during `/foundation` when the Frontend Developer catalogs `src/design-handoff/`.

**If you're looking for the old Phase 3 workflow:**
- Design prompt guidance → `artifacts/docs/design-brief.md` (produced by `/phase2`)
- Component inventory → produced during `/foundation` (see `.cursor/skills/design-system/SKILL.md`)
- Token config → the adapter's CSS custom properties (`theme.css` with `@theme inline`) copied into `src/app.css` during `/foundation`

**The workflow is now:**
1. `/phase2` → screen specs + design brief
2. `/design` → run the configured design tool per its adapter SKILL → adapter exports handoff bundle to `src/design-handoff/` → `/design verify` passes
3. `/phase4` → tech spec (schema derived from the adapter's mock data)
4. `/setup` → build plan
5. `/foundation` → backend infra + component inventory + landing page + auth
