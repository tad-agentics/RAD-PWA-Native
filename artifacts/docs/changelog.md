# Changelog — [App Name]

## v3.1 — Impeccable Integration (2026-04-24)

Absorbed selected content from Impeccable v2.1.1 (https://impeccable.style, Apache 2.0) to fill gaps in RAD's QA and design-reference coverage.

**Reference library added:**
- 9 reference files at `artifacts/docs/design-principles/` — typography, color-and-contrast, spatial-design, motion-design, interaction-design, responsive-design, ux-writing, craft, extract
- Wired into `artifacts/templates/design-context-template.md` and `.cursor/skills/wireframes/SKILL.md` so every design brief cites them

**QA-layer skills added (four):**
- `/audit` (audit-rad@1.0.0) — technical quality scored P0-P3 across 5 dimensions
- `/critique` (critique-rad@1.0.0) — UX design review via persona sub-agents + Nielsen heuristics
- `/harden` (harden-rad@1.0.0) — production-readiness gap flagging
- `/optimize` (optimize-rad@1.0.0) — UI performance diagnostics vs RAD baseline

All four wired into `/pre-handoff` as Passes 6-9 (advisory; route findings to Tech Lead triage per each skill's remediation paths).

**UX-writing patterns merged into copy-rules.mdc:**
- `/clarify` content absorbed as the "UX Writing Principles" section (rule-shape, not skill-shape) so every agent session has UX-writing principles auto-loaded.

**Explicitly NOT imported:**
- `/impeccable`, `/shape`, `/impeccable teach`, `/impeccable craft` — conflict with RAD's Phase 1/Phase 2
- `/polish`, `/typeset`, `/layout`, `/colorize`, `/animate`, `/bolder`, `/quieter`, `/distill`, `/overdrive`, `/delight`, `/adapt` — design-layer creative operations; belong in the adapter step, not integration

**Scope-adjusted from upstream:** `/harden` and `/optimize` FLAG findings rather than auto-implement fixes. Non-trivial remediation routes through `/design new-feature` to preserve RAD's 90% untouched rule.

**Attribution:** See `artifacts/docs/design-principles/NOTICE.md` + each skill's NOTICE.md.

**Install tree NOT committed:** Impeccable's `.agents/`, `.claude/`, `skills-lock.json` explicitly excluded (see `.gitignore`). This is a fork, not a dependency.

---

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
