# Design Adapters

This directory contains adapter skills that normalize AI design tool output into RAD's canonical handoff shape. The pipeline (commands, rules, agents) is tool-agnostic — it reads only the canonical handoff per `artifacts/docs/handoff-contract.md` v3. Adapters are the only place tool-specific knowledge lives.

Per-project adapter selection: `artifacts/design-tool.config.json`.

---

## Active adapters

| Adapter | Tool | Version | Targets contract | Notes |
|---|---|---|---|---|
| `claude-design-adapter` | Anthropic Claude Design | 1.0.0 | v3 | Default. Repo-linked token fidelity. Requires Claude Pro/Max/Team/Enterprise. Enforces C2/C3/H1/H2/H3/H4. |
| `manual-adapter` | None (escape hatch) | 1.0.0 | v3 | Validation-only. Human produces canonical bundle directly. Use during tool outages or when no adapter exists yet. |

## Planned adapters

| Adapter | Tool | Status |
|---|---|---|
| `figma-make-adapter` | Figma Make | Not started — legacy tool, low priority |
| `stitch-adapter` | Google Stitch | Not started — author when studio needs it |
| `figma-mcp-adapter` | Figma Dev Mode MCP + Code Connect | Not started — high-fidelity option for mature design systems |

---

## Authoring a new adapter

### Step 1 — Copy the template

Start from `claude-design-adapter/` as the template. It has the full shape: SKILL.md with frontmatter + adapter contract + discard list + enforcement gates, plus a `scripts/` directory.
cp -r .cursor/skills/design-adapters/claude-design-adapter .cursor/skills/design-adapters/[tool]-adapter

### Step 2 — Update frontmatter

Replace:
- `name: [tool]-adapter`
- `description:` tool-specific one-liner
- `version: [tool]-adapter@1.0.0` (start at 1.0.0; bump per the semver guidance below as the adapter evolves)
- `targets_contract_version: "3.1"` (current — bump when a future contract version ships)

### Step 3 — Rewrite the adapter contract section

Document how the tool's output maps to the canonical shape:
1. What format does the tool export? (ZIP, URL, file bundle, API response)
2. What's in the output that isn't canonical? (goes to discard list)
3. How does the adapter build `handoff-manifest.json`? (which tool metadata feeds which manifest field)
4. How does the adapter build `design-context.md`? (how are the 9 sections populated from tool output + EDS)
5. What's the final file-move sequence into canonical structure?

### Step 4 — Define the discard list

Every tool ships scaffold files that break RAD's build or conflict with its conventions. List them in `## Discard list` with the reason for each. Example from claude-design-adapter: `vite.config.*` discarded because RAD has its own locked config.

### Step 5 — Author tool-specific verification scripts

Decide which gates the adapter enforces. For reference, claude-design-adapter runs:
- C2 (repo-link token diff) — unique to tools with repo-awareness
- C3 (design-context substance) — generalizes; every adapter could run this
- H1 (prompt budget) — applicable to any AI tool with a turn quota
- H3 (regen shape) — applicable to any adapter supporting drift regen
- H4 (version drift) — applicable to any AI tool whose output schema can drift

New adapters should enforce whichever gates are relevant. Manual-adapter enforces none (canonical checks are sufficient). Scripts live in `[tool]-adapter/scripts/`.

### Step 6 — Update the config example

Add the new adapter to `artifacts/design-tool.config.json`'s `tool_settings` example so users know it's available:

```json
{
  "adapter": "claude-design",
  "fallback_adapters": ["manual"],
  "tool_settings": {
    "claude-design": { ... },
    "manual": { ... },
    "[tool]": {
      "[setting_1]": "value",
      "[setting_2]": "value"
    }
  }
}
```

### Step 7 — Smoke test

Produce a minimal handoff with the tool end-to-end. Confirm:
- `/design verify` passes canonical checks
- `/design verify` passes the adapter's tool-specific checks
- Foundation consumes the handoff without errors
- A single screen ports from handoff → `src/routes/` cleanly

### Step 8 — Add to this README

Move the adapter from "Planned" to "Active" with its version and notes.

---

## Adapter compliance checklist

Every new adapter MUST satisfy:

- [ ] SKILL.md frontmatter includes `name`, `version`, `targets_contract_version`, `disable-model-invocation: true`
- [ ] SKILL.md has `## Adapter contract` section describing normalization steps
- [ ] SKILL.md has `## Discard list` section (can be empty for adapters like manual-adapter)
- [ ] SKILL.md has `## Enforcement gates` section (can state "none" for validation-only adapters)
- [ ] Normalization produces valid `handoff-manifest.json` matching `artifacts/templates/handoff-manifest-schema.json`
- [ ] Normalization produces `design-context.md` with all 9 required H2 sections populated
- [ ] Canonical shape matches `artifacts/docs/handoff-contract.md` §Canonical handoff shape
- [ ] No forbidden contents per contract §Forbidden contents
- [ ] `scripts/test-adapter-switch.sh` passes against the adapter's output (extend the test if needed)
- [ ] Adapter is listed in this README's Active section

---

## When NOT to author an adapter

- The tool's output is too lossy to produce canonical shape — e.g. tools that silently reinvent tokens without a repo link (Planned adapters in this class, like Figma Make, need extra discard + token-diff work before they ship)
- The adapter would be a re-skin of an existing one (use the existing adapter with different `tool_settings` instead)
- The tool is unstable/beta and the studio doesn't need it for active projects (wait — adapters are cheap to add later)

---

## Versioning

Adapter semver rules:

- **Patch (1.0.0 → 1.0.1):** bug fixes in normalization scripts
- **Minor (1.0.0 → 1.1.0):** new gate added, new tool-specific field handled, backward-compatible
- **Major (1.0.0 → 2.0.0):** breaking change — projects pinned to 1.x must migrate or stay on the old adapter

Contract version targets are separate from adapter semver. An adapter targets one contract version at a time (`targets_contract_version: "3.1"` currently). When the contract bumps (v3 → v3.1 was a backward-compatible minor; a future v4 would be breaking), the adapter ships a corresponding semver bump to track it.

---

## Directory structure
.cursor/skills/design-adapters/
├── README.md                           ← this file
├── claude-design-adapter/
│   ├── SKILL.md
│   └── scripts/
│       ├── check-feature-design-prereq.sh
│       ├── rollup-prompt-budget.sh
│       ├── verify-handoff-notes.sh
│       ├── verify-handoff-tokens.sh
│       └── verify-regen-shape.sh
├── manual-adapter/
│   └── SKILL.md                        (no scripts — validation-only)
└── [tool]-adapter/                     (future)
├── SKILL.md
└── scripts/
└── [tool-specific gates]
