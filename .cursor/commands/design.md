## /design

Adapter dispatcher for RAD's tool-agnostic design step. Reads `artifacts/design-tool.config.json` to determine which adapter to run, then delegates pre-flight, human-driver instructions, and post-flight verification to that adapter's SKILL.

Not an agent dispatch — this command is a checklist with scripted checks. The human drives the design tool; this command orchestrates the workflow around it.

Usage:
- `/design` — initial build (after `/phase2`)
- `/design new-feature [name]` — incremental design for a new feature
- `/design regen [screen]` — drift regen for a single screen
- `/design verify` — re-run canonical + adapter-specific verification without re-running the tool
- `/design verify new-feature [name]` — verify an incremental bundle
- `/design verify regen [screen]` — verify a regen bundle

---

## Step 1 — Read adapter config

Read `artifacts/design-tool.config.json` at the project root. Extract:
- `adapter` → primary adapter name (e.g. `"claude-design"` or `"manual"`)
- `fallback_adapters` → ordered list of fallbacks
- `tool_settings.[adapter]` → adapter-specific settings

If the config file does not exist, halt and report:
> `artifacts/design-tool.config.json` is missing. Either run `/init` to scaffold it, or create it manually. Default adapter is `claude-design`. See `.cursor/skills/design-adapters/` for all available adapters.

The configured adapter must have a corresponding SKILL file at `.cursor/skills/design-adapters/[adapter]-adapter/SKILL.md`. If it does not, halt and report:
> `adapter: "[X]"` in config but no `.cursor/skills/design-adapters/[X]-adapter/SKILL.md` exists. Either author the adapter or change the config to a valid adapter name.

---

## Step 2 — Resolve mode

Determine mode from the command arguments:
- No argument → `initial` mode. Requires: `src/design-handoff/` does NOT yet exist (or is empty).
- `new-feature [name]` → incremental mode. Requires: `artifacts/docs/features/[name].md` exists.
- `regen [screen]` → drift regen mode. Requires: recent `/visual-audit` report flagged this screen.
- `verify [mode] [arg]` → skip human step, run verification only.

Validate prerequisites for the mode. If any fail, halt with a specific remediation message.

---

## Step 3 — Adapter pre-flight

Read `.cursor/skills/design-adapters/[adapter]-adapter/SKILL.md`. Locate its pre-flight section for the requested mode. Run every pre-flight check defined there.

The canonical pre-flight (runs regardless of adapter) includes:
- `artifacts/docs/screen-specs-[app]-v1.md` exists (for initial + new-feature modes)
- `artifacts/docs/northstar-[app].html` exists (for initial mode)
- `artifacts/docs/design-brief.md` exists (for initial + new-feature modes; produced by Phase 2 product-designer)

The adapter's pre-flight may add tool-specific gates — e.g. the `claude-design-adapter` runs the H1 prompt-budget guard via `.cursor/skills/design-adapters/claude-design-adapter/scripts/rollup-prompt-budget.sh`.

If any pre-flight check fails with BLOCKING, halt. Report the exact check that failed and the adapter SKILL's remediation guidance. Do not proceed to human step.

---

## Step 4 — Human-driver step

Present the adapter's human-driver instructions to the Tech Lead. These come from the adapter's SKILL.md §Prompting Patterns (or equivalent section) for the requested mode.

For the default `claude-design` adapter, the human instructions point at the Claude Design product and describe repo linking, brief pasting, iteration, and dual-artifact export. For `manual-adapter`, the human instructions describe producing the bundle by hand.

The command's role at this step is presentational. Do not execute the design tool — the human does that. When the human confirms the export/production step is complete, proceed to Step 5.

---

## Step 5 — Adapter normalization

Invoke the adapter's normalization step if the adapter supports one. The `claude-design-adapter` unzips the Claude Design export, deletes discard-list files, generates `handoff-manifest.json`, produces `design-context.md`, and moves files into canonical structure. The `manual-adapter` has no normalization (the human produced canonical output directly).

The normalization step details are in the adapter's SKILL.md §Adapter contract. Run them as documented.

If normalization fails (e.g. required files missing from the tool's output, malformed manifest), halt with the specific normalization step that failed.

---

## Step 6 — Verify (canonical + adapter-specific)

`/design verify` runs two layers:

**Layer 1 — Canonical checks** (every adapter):
- `handoff-manifest.json` exists and validates against `artifacts/templates/handoff-manifest-schema.json` (accepts `contract_version` "3" or "3.1")
- For contract v3.1 handoffs: `npx @google/design.md@0.1.1 lint src/design-handoff/design-context.md` returns zero errors. Warnings (typically WCAG AA contrast) surface to Tech Lead but don't block. v3 handoffs skip this check.
- `design-context.md` exists with all 9 required H2 prose sections, each populated (not template placeholders)
- Required shape per contract v3.1 §Canonical handoff shape (theme.css, components/ui/ ≥ 5 files for initial mode, routes/ or screens/ with one file per screen in spec)
- Forbidden contents absent — `globals.css`, Next.js files, `.env` files must never appear in the handoff (contract v3.1 §Forbidden contents)

### Running the lint

Inspect `handoff-manifest.json` to determine `contract_version`. If `"3.1"`, run:

```bash
npx @google/design.md@0.1.1 lint src/design-handoff/design-context.md
```

The lint returns structured JSON. Parse `summary.errors` — if > 0, halt verification and surface the `findings` array to the Tech Lead with the specific path + message for each error. If `summary.errors == 0`, proceed regardless of `summary.warnings` (warnings log to `design-tool-log.md` but don't block).

Lint errors typically indicate:

- Broken token references in the `components` section (e.g. `"{colors.missing-name}"`)
- Malformed YAML structure
- Color values outside valid hex format
- Missing required sections in YAML

Lint warnings typically indicate:

- WCAG AA contrast below 4.5:1 on color combinations the adapter declared in `components`
- Schema conformance hints

If lint errors persist after the Tech Lead's fix attempt, the remediation path is: re-run the adapter with a more specific brief (for `claude-design-adapter`) or edit `design-context.md` manually to resolve (for `manual-adapter`).

**Layer 2 — Adapter-specific checks** (from the adapter's SKILL.md §Enforcement gates):
- For `claude-design-adapter`: C2 token diff, C3 design-context substance, H1 prompt budget, H3 regen shape, H4 version drift
- For `manual-adapter`: none (canonical checks only)
- For future adapters: whatever gates the adapter defines

Report per-check PASS/FAIL. On any BLOCKING fail, halt and instruct the human to fix before proceeding to `/foundation` or `/feature`.

---

## Step 7 — Log the session

Append an entry to `artifacts/docs/design-tool-log.md` using the machine-parseable header format. Required fields:
- `adapter` — from config
- `tool_version` — from the adapter's normalization (or `n/a` for manual)
- `prompts_consumed` — H1 metric (0 for manual)
- `shape_mismatch` — H4 metric (set by Step 6 verification)
- `export_target` — path where handoff landed
- `verification` — pass | fail-then-fixed-on-N | failed

`/session-end` reads these rollups to track prompt budget and schema drift over time.

---

## Switching adapters mid-project

If the primary adapter fails (tool outage, breaking schema change, quota exceeded), edit `artifacts/design-tool.config.json`:

```json
{
  "adapter": "manual",
  "fallback_adapters": [],
  "tool_settings": {
    "manual": { "validate_shape_only": true }
  }
}
```

Re-run `/design`. The pipeline, agents, rules, and commands are tool-agnostic — only the adapter changes. Record the switch as an entry in `artifacts/docs/design-tool-log.md` with rationale in the notes field.

---

## Troubleshooting

**Pre-flight fails for missing artifacts/docs/design-brief.md:** Run `/phase2` first. The product-designer produces the design brief.

**Adapter not found in .cursor/skills/design-adapters/:** Check the adapter name in `artifacts/design-tool.config.json` matches a directory under `.cursor/skills/design-adapters/[name]-adapter/`. Note the `-adapter` suffix.

**Canonical verification fails but adapter-specific passes:** The handoff violates the canonical contract (v3 or v3.1, whichever is declared in `handoff-manifest.json.contract_version`). Check `handoff-manifest.json` schema compliance and `design-context.md` section completeness first — these are the contract requirements adapters may be under-producing. For v3.1 handoffs, also check the DESIGN.md lint output for malformed YAML frontmatter.

**Adapter-specific verification fails:** Read the adapter SKILL's §Failure Modes section. Most failures have documented fixes.

**DESIGN.md lint fails with network error:** The lint command uses `npx` which downloads `@google/design.md@0.1.1` on first run. If offline or network-restricted, either: (a) pre-install locally via `npm i -g @google/design.md@0.1.1` before running `/design verify`, or (b) switch the active adapter to `manual-adapter` and manually validate the YAML against `artifacts/templates/handoff-manifest-schema.json`.

**Need a new adapter:** See `.cursor/skills/design-adapters/README.md` (created in Milestone 5) for the authoring contract.
