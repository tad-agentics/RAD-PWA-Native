# Changelog — [App Name]

## v3 — Tool-Agnostic Design Adapter Layer (2026-04-23)

Refactored the design tool integration from a Claude Design–specific pipeline to a ports-and-adapters architecture. RAD now supports any AI design tool via a thin adapter skill, with the pipeline remaining tool-agnostic.

**Key changes:**
- `artifacts/docs/handoff-contract.md` rewritten as v3 — canonical shape produced by every adapter, adapter-scoped discard lists, adapter-specific verification (C2/C3/H1/H2/H3/H4 scoped to `claude-design-adapter`).
- Added `handoff-manifest.json` (metadata) + `design-context.md` (universal design system doc) as required artifacts at the root of every canonical handoff.
- Added `artifacts/design-tool.config.json` for per-project adapter selection.
- Adapter folder: `.cursor/skills/design-adapters/[tool]-adapter/` — scoped SKILL + scripts.
- Default adapter (`claude-design`) preserves all v2 enforcement gates (C2/C3/H1/H2/H3/H4); escape hatch (`manual`) available for tool outages.
- 49-file coupling surface reduced to tool-agnostic vocabulary across commands, rules, agents, skills, artifacts, and root docs.

**Planned adapters (not shipped in this refactor):** `figma-make-adapter`, `stitch-adapter`, `figma-mcp-adapter`.

**Migration:** Existing projects work unchanged if they stay on `claude-design`. To switch tools mid-project, edit `artifacts/design-tool.config.json` and re-run `/design`.

**Refactor landed:** 2026-04-23. All 5 milestones (M1 contract, M2 pipeline decoupling, M3 adapter refactor, M4 renames + dispatcher, M5 tests + docs) complete. Integration test at `scripts/test-adapter-switch.sh` validates adapter switching. Active adapters: `claude-design-adapter@1.0.0`, `manual-adapter@1.0.0`.

---

## How to use

- Add one row per deviation discovered during build — takes 30 seconds
- Do NOT edit specs mid-build — log the deviation here instead
- BLOCKING = can't continue the current feature without resolving this → fix before marking the feature complete
- NON-BLOCKING = log and continue → batch-fix before pre-handoff review (after all features pass QA)
- Move to RESOLVED when fixed, including the commit hash

## Active

| Feature | What changed | Blocking? | Fixed? | Commit |
|---|---|---|---|---|

## Resolved

| Feature | What changed | Resolved | Commit |
|---|---|---|---|
