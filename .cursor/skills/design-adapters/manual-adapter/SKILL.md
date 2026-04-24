---
name: manual-adapter
description: RAD design adapter for manual handoff. Human drops a pre-built hybrid-format handoff bundle (DESIGN.md YAML frontmatter + RAD prose) into src/design-handoff/ directly. The adapter only validates shape against contract v3.1. Use when no AI design tool is available, or as an escape hatch during tool outages.
disable-model-invocation: true
version: manual-adapter@1.1.0
targets_contract_version: "3.1"
---

# Manual Adapter

Validation-only adapter. No AI design tool involved. The human (or team designer) produces a handoff bundle that already matches the canonical shape, and this adapter validates it.

## When to use

- **Primary AI design tool is down** — outage, quota exceeded, breaking schema change. Switch `artifacts/design-tool.config.json` → `"adapter": "manual"` and keep shipping.
- **Project uses a design tool not yet adapterized** — Planned adapters like Figma Make, Stitch, or Figma MCP can use the manual adapter as a stand-in until their tool-specific adapters ship.
- **Human designer produces the handoff directly** — hand-coded TSX, output from another pipeline, or bespoke design work.

## Human workflow

1. Produce a handoff bundle matching `artifacts/docs/handoff-contract.md` v3.1 exactly (canonical shape, required properties, no forbidden contents).
2. Place it at `src/design-handoff/` (or `new-feature-[name]/` or `regen-[screen]/` for incremental modes).
3. Write `src/design-handoff/handoff-manifest.json` by hand per the schema at `artifacts/templates/handoff-manifest-schema.json`. Required fields for contract v3.1:
   - `contract_version: "3.1"`
   - `source_tool: "manual"`
   - `adapter: "manual-adapter@1.1.0"`
   - `mode: "initial" | "new-feature" | "regen"`
   - `generated_at`, `screens_exported`
   - `canonical` — object with:
     - `repo_linked_at_generation: false` (manual adapter has no tool to link)
     - `tokens_match_app_css: null` for initial builds; boolean for incremental
     - `design_md_version: "0.1.1"` — the DESIGN.md spec version the YAML frontmatter targets
4. Write `src/design-handoff/design-context.md` in hybrid format following `artifacts/templates/design-context-template.md`:
   a. YAML frontmatter at top (between `---` delimiters) with `version: alpha`, `design_md_version: "0.1.1"`, and all required token groups (colors, typography, rounded, spacing, components). Flat hex values — no token references.
   b. All 9 prose H2 sections populated below the frontmatter: Brand, Color System, Typography, Spacing, Components, Interaction Patterns, Anti-Patterns, Copy Rules, Build Constraints.
   c. No template placeholders remaining — `[placeholder]` markers cause `/design verify` to fail.
5. Run `/design verify` (canonical checks only — no adapter-specific gates).

## Adapter contract

This adapter does NOT run normalization. The human produces canonical output directly. The adapter's responsibility is limited to:

1. Asserting the manifest file exists and validates against the JSON schema
2. Asserting the design-context.md has valid YAML frontmatter (DESIGN.md v0.1.1)
3. Asserting the design-context.md has all 9 required H2 prose sections with populated content (not template placeholders)
4. Running `npx @google/design.md@0.1.1 lint src/design-handoff/design-context.md` — any errors halt handoff; warnings surface to Tech Lead
5. Delegating all other checks to the canonical `/design verify` layer

## Discard list

None. Manual-adapter consumers produce clean bundles directly. There are no scaffold files to delete.

## Enforcement gates

Manual adapter runs only the canonical + lint checks. The human is accountable for correctness on substance:

- **L1 (DESIGN.md lint)** — enforced via `npx @google/design.md@0.1.1 lint`
- No C2 (no tool to repo-link), no C3 handoff-notes substance check (manual handoffs don't have the 4-subsection claude-design structure)
- No H1 prompt budget (no AI tool involved), no H2 native-brief cap, no H3 regen shape check, no H4 version drift anchor

This is the intentional trade-off: less automation, more resilience. The pipeline is guaranteed to accept the output if shape + YAML lint pass. Use this adapter whenever a tool-specific adapter is failing, then switch back once the tool stabilizes.

## Escalation

If the human produces a handoff that fails canonical verification:
- Missing/malformed manifest → fix per schema
- design-context.md sections empty or placeholder-only → populate with real content
- Discard list violations (e.g. `globals.css`, Next.js conventions, never accepted in v3) → delete
- Required primitives missing → author them (hand-coded primitives are acceptable; they just have to exist and export cleanly)

If the project repeatedly lands on manual adapter because no AI design tool is stable enough, escalate to Tech Lead: the studio may need to prioritize authoring a new tool-specific adapter.

## Logging

Append an entry to `artifacts/docs/design-tool-log.md` per session, same machine-parseable header format as other adapters. Required fields:
[YYYY-MM-DD HH:mm] [initial | new-feature-[name] | regen-[screen]]
adapter: manual-adapter
tool_version: n/a
prompts_consumed: 0
shape_mismatch: [yes | no]
shape_mismatch_notes: [if yes]
export_target: [src/design-handoff/... path]
verification: [pass | fail-then-fixed-on-N | failed]

`prompts_consumed: 0` always — no AI tool involved.
