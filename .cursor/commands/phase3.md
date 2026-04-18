# /phase3

> **Phase 3 is absorbed into Claude Design + Foundation.** This command is not dispatched separately.

Claude Design handles visual design (colors, typography, spacing, components). The design system component inventory is produced during `/foundation` when the Frontend Developer catalogs `src/design-handoff/`.

**If you're looking for the old Phase 3 workflow:**
- Claude Design prompt guidance → `artifacts/docs/claude-design-brief.md` (produced by `/phase2`)
- Component inventory → produced during `/foundation` (see `.cursor/skills/design-system/SKILL.md`)
- Token config → Claude Design's CSS custom properties (`theme.css` with `@theme inline`) copied into `src/app.css` during `/foundation`

**The workflow is now:**
1. `/phase2` → screen specs + Claude Design prompt brief
2. Human builds in Claude Design → exports handoff bundle to `src/design-handoff/`
3. `/phase4` → tech spec (schema derived from Claude Design's mock data)
4. `/setup` → build plan
5. `/foundation` → backend infra + component inventory + landing page + auth
