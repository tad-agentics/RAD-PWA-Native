# Design Tool → RAD Handoff Contract

This is the file-level contract between **any AI design tool** (via its adapter) and RAD's integration pipeline. If an adapter's output does not meet this contract, `/design verify` fails and the handoff is rejected before `/foundation` or `/feature` run.

**Contract version: 3** (tool-agnostic — adapters normalize tool output to the canonical shape below).

Previous versions (v1, v2) were coupled to Claude Design. v3 decouples the contract from any specific tool. The canonical shape, required properties, and forbidden contents apply to **every** adapter. Tool-specific concerns (prompting patterns, discard lists, verification extras) live in the adapter's SKILL, not here.

---

## Architecture
AI design tool  →  adapter (SKILL + scripts)  →  canonical handoff  →  RAD pipeline
(varies)           (tool-specific)              (this contract)       (tool-agnostic)

The pipeline, agents, rules, and commands read only the canonical handoff. They never reference the source tool. An adapter is a skill at `.cursor/skills/design-adapters/[tool-name]-adapter/` that handles the human workflow for its tool and normalizes the tool's output to match this contract.

See `.cursor/skills/design-adapters/README.md` for the adapter authoring contract.

---

## Canonical handoff shape

Every adapter produces `src/design-handoff/` matching this shape, regardless of source tool.

### Initial build — `src/design-handoff/`
src/design-handoff/
├── handoff-manifest.json       — adapter-written metadata (schema below)
├── design-context.md           — universal design system doc (structure below)
├── theme.css                   — CSS custom properties + @theme inline (Tailwind v4)
├── components/
│   ├── ui/                     — shared UI primitives (Button, Card, Dialog, …)
│   │   └── [≥ 5 primitive files]
│   └── [app-level shared components, optional — e.g. ScreenHeader, CreditGate]
├── routes/ or screens/         — one file per screen in screen-specs-[app]-v1.md
│   └── [screen].tsx
├── mock-data/ (optional)       — hardcoded entity mocks (or inline)
└── assets/ (optional)          — images/fonts the adapter produces

An entrypoint file (`App.tsx` or `routes.tsx`) is **optional** in v3. When present, it wires every screen with resolvable routes. The Frontend agent uses it as a reference map only; never copies it into `src/`.

### Incremental — `src/design-handoff/new-feature-[name]/`
src/design-handoff/new-feature-[name]/
├── handoff-manifest.json       — mode: "new-feature", feature_name: "[name]"
├── design-context.md           — appendix for new components/tokens, if any
├── routes/ or screens/
│   └── [screen].tsx            — only the new screens for this feature
└── mock-data/                  — only mocks for new entities, if any

**Must not contain** `components/ui/` — primitives are locked after Foundation.

### Drift regen — `src/design-handoff/regen-[screen]/`
src/design-handoff/regen-[screen]/
├── handoff-manifest.json       — mode: "regen", feature_name: "[screen]"
└── [screen].tsx                — single-file regen, mock-data shape preserved

---

## Handoff manifest

Every canonical handoff has a `handoff-manifest.json` at its root. Adapters write this file as part of their normalization step. The pipeline reads only canonical fields; adapters may add tool-specific fields under `tool_specific` without affecting downstream consumers.

### Schema

```json
{
  "contract_version": "3",
  "source_tool": "claude-design | figma-make | stitch | figma-mcp | manual",
  "tool_version": "string — e.g. 'beta-2026-04' or 'unknown'",
  "generated_at": "ISO-8601 timestamp",
  "adapter": "adapter-name@semver — e.g. 'claude-design-adapter@1.0.0'",
  "mode": "initial | new-feature | regen",
  "feature_name": "string | null",
  "screens_exported": "integer",
  "primitives_exported": "integer",
  "canonical": {
    "repo_linked_at_generation": "boolean — adapter records whether the tool had repo context",
    "tokens_match_app_css": "boolean | null — null if app.css doesn't exist yet (initial build)"
  },
  "tool_specific": {
    "// free-form adapter-scoped fields": "e.g. claude_design_bundle_url, figma_node_ids, stitch_design_md_hash"
  },
  "notes": "free text — adapter-specific context"
}
```

### Required fields

- `contract_version` — must be `"3"` for contracts produced against this spec
- `source_tool` — one of the enum values
- `generated_at` — ISO-8601 timestamp
- `adapter` — adapter name + semver (pins which adapter version produced this)
- `mode` — one of `initial`, `new-feature`, `regen`
- `screens_exported` — integer count
- `canonical` — object with `repo_linked_at_generation` (required) and `tokens_match_app_css` (required, nullable)

Optional fields: `tool_version`, `feature_name` (required if mode ≠ initial), `primitives_exported`, `tool_specific`, `notes`.

### Validation schema

JSON schema lives at `artifacts/templates/handoff-manifest-schema.json` (created in Step 2). `/design verify` validates every manifest against that schema before running downstream checks. Manifests failing schema validation are BLOCKING.

---

## Design context document

Every canonical handoff has a `design-context.md` at its root. Adapters produce this from EDS §5 (brand) plus the source tool's extracted tokens. All adapters produce the same structure — the pipeline reads the same shape regardless of which tool generated the handoff.

### Required sections

```markdown
# Design Context — [App Name]

## Brand
- Voice, personality (3 words), anti-references — from EDS §1, §2

## Color System
- Token table with hex + oklch + semantic role — from EDS §5

## Typography
- Display font, body font, modular scale — from EDS §5

## Spacing
- Base unit + scale

## Components
- Primitive list with variants and sizes

## Interaction Patterns
- From EDS §4

## Anti-Patterns
- From EDS §8 + design-system.mdc Slop Guard

## Copy Rules
- Language, forbidden words, screen-context rules — from copy-rules.mdc

## Build Constraints
- Framework, styling approach, component library, font hosting
```

### Source of content

- Sections 1–6 (Brand, Color, Typography, Spacing, Components, Interaction Patterns) — the adapter extracts these from the source tool's output (theme tokens, component library, interaction metadata) and cross-checks against EDS §5. If the tool didn't produce a value, the adapter falls back to EDS §5 as source of truth.
- Sections 7–9 (Anti-Patterns, Copy Rules, Build Constraints) — the adapter populates these from the existing RAD files (EDS §8, copy-rules.mdc, project.mdc). These do not depend on the source tool.

### Template

`artifacts/templates/design-context-template.md` (created in Step 2) is the starting template. Adapters begin from it and fill in every section. Placeholders (`[placeholder]`) must be replaced with real content before `/design verify` will pass.

### Enforcement

`/design verify` parses `design-context.md` and requires:

1. Every section listed above is present as an H2 heading
2. Each section contains ≥ 1 content line below the heading (excludes blank lines and any line that is exactly a placeholder like `[placeholder]` or `TODO`)
3. The `## Color System` section contains ≥ 3 token rows
4. The `## Components` section contains ≥ 5 primitive rows (for initial builds — new-feature appendices may contain fewer)

Failures are BLOCKING. The Frontend agent's design intent comes from this file; sparse content means sparse integration quality.

---

## Required properties

| # | Property | Rule |
|---|---|---|
| 1 | Manifest | `handoff-manifest.json` exists at the handoff root with valid required fields per the schema in "## Handoff manifest" |
| 2 | Context | `design-context.md` exists at the handoff root with all required sections populated per "## Design context document" |
| 3 | Theme | `theme.css` uses CSS custom properties + Tailwind v4 `@theme inline` (no `tailwind.config.ts`) |
| 4 | Primitives (initial only) | `components/ui/` contains ≥ 5 files; each file exports one primitive. New-feature and regen modes skip this check. |
| 5 | Screen coverage | Every screen in `artifacts/docs/screen-specs-[app]-v1.md` has a matching file |
| 6 | Mock data | Inline or colocated; **no** `fetch`, `axios`, `supabase`, or network calls |
| 7 | Imports | All relative imports resolve within the handoff bundle — no `@/` aliases pointing outside the bundle |
| 8 | Typography | `@font-face` declarations or Google Fonts `@import` in `theme.css` (fonts are self-hosted during Foundation) |
| 9 | Assets | Images referenced via imports or public URLs — no local `/public/` absolute paths |

An entrypoint file (`App.tsx` or `routes.tsx`) is **not** a required property in v3. If the source tool produces one, the adapter may preserve it; the Frontend agent uses it as a reference map only and never copies it into `src/`.

---

## Forbidden contents

These cause `/design verify` to fail, regardless of adapter:

- `globals.css` — RAD uses `src/app.css`
- `app/` directory or `page.tsx` files — Next.js conventions, not React Router
- `next.config.*`, `next-env.d.ts` — Next.js config
- `node_modules/`, `package-lock.json`, `yarn.lock` — install happens in Foundation Step 0
- `src/make-import/`, `figma-make-brief.*` — legacy Figma Make tokens (superseded by adapter layer)
- Any `.env*` files — secrets never flow through design handoff
- Any file matching the active adapter's discard list — per the adapter SKILL's `## Discard list` section (see "## Discard list — adapter-scoped" below)

## Discard list — adapter-scoped

Previous contract versions (v1, v2) embedded a discard list for Claude Design's scaffold files directly in this document. In v3, **every adapter owns its own discard list**. The canonical contract asserts only required and forbidden contents (above). Per-tool scaffold handling is the adapter's job, not the pipeline's.

Each adapter's SKILL.md contains a `## Discard list` section listing files the adapter deletes during normalization. Examples (informational — see each adapter's SKILL for the authoritative list):

| Adapter | Typical discards |
|---|---|
| `claude-design-adapter` | `index.html`, `vite.config.*`, root `package.json`, `tsconfig*.json`, `tailwind.config.*`, `postcss.config.*`, root `README.md`, preview scaffolds, default logos, `*.stories.tsx` |
| `figma-make-adapter` | Make's stage wrappers, mock router, conflicting `App.tsx` |
| `stitch-adapter` | Stitch's CDN Tailwind import, sample images, HTML shell |
| `figma-mcp-adapter` | Typically none — MCP returns clean snippets, not project scaffolds |
| `manual-adapter` | None — the human produces a clean bundle directly |

If a file appears in a handoff that is neither in the canonical "## Required properties" list nor in the active adapter's discard list, the Frontend agent escalates to the Tech Lead. The adapter owner updates the adapter's discard list accordingly and re-normalizes; the contract itself is not amended.

---

## Adapter-specific verification

The canonical `/design verify` runs the shape/forbidden/required checks above for every adapter. Adapters may add **tool-specific** verification on top, and the `/design verify` dispatcher calls the active adapter's verification scripts alongside the canonical checks.

### Enforcement gates preserved from v2

These gates existed in v2 as Claude Design-specific enforcement. In v3 they are **scoped to the `claude-design-adapter`** and continue to run whenever that adapter is active:

| Gate | Concern | Script (under `claude-design-adapter/scripts/`) |
|---|---|---|
| C2 | Repo link was active — tokens match `src/app.css`, not invented | `verify-handoff-tokens.sh` |
| C3 | `design-context.md` substance — four required subsections each with ≥ 20 content lines | `verify-handoff-notes.sh` |
| H1 | Prompt-budget guard — rolling 30-day window, WARN at ≥ 40 turns, BLOCK at ≥ 50 | `rollup-prompt-budget.sh` |
| H2 | Native-targeted brief budget — hard cap of 3 per feature, Tech Lead override required for 4th | enforced via feature doc `native_brief_count` field |
| H3 | Regen shape — exactly one `.tsx` file, no invented primitives | `verify-regen-shape.sh` |
| H4 | Version-drift anchor — consecutive `shape_mismatch: yes` entries trigger contract review | `rollup-prompt-budget.sh` (combined with H1) |

### New adapters implement their own gates

When authoring a new adapter (`stitch-adapter`, `figma-mcp-adapter`, etc.), the adapter owner decides which tool-specific concerns need scripted gates. Examples:

- A `figma-mcp-adapter` might add a gate verifying Code Connect mappings resolve to existing components.
- A `stitch-adapter` might add a gate verifying `DESIGN.md` token values round-trip into `design-context.md` without loss.
- A `manual-adapter` runs only canonical checks — the human is accountable for correctness.

Tool-specific gates live in the adapter's `scripts/` directory. The adapter's SKILL.md documents which gates it enforces and their BLOCKING/WARN semantics.

### Pipeline stays tool-agnostic

Downstream files (commands, rules, agents) reference only the canonical `/design verify` dispatcher. They never call adapter-specific scripts directly. If an adapter's script needs to halt the pipeline, it exits non-zero and `/design verify` propagates the failure.

---

## What Foundation does with this

Step 0 — Install dependencies: scan imports across all `src/design-handoff/**/*.tsx`, run `npm install [packages]`.

Step 1 — Move as-is:
- `src/design-handoff/components/ui/` → `src/components/ui/`
- Other shared components in `src/design-handoff/components/` → `src/components/`

Step 2 — Copy theme:
- `src/design-handoff/theme.css` → appended into `src/app.css`
- Replace Google Fonts CDN `@import` with self-hosted `.woff2` via `@font-face`

Step 3 — Copy-then-edit screens:
- Each `src/design-handoff/[screen].tsx` copied directly into `src/routes/_app/[feature]/route.tsx`
- Targeted edits: swap mock data → Supabase hook, fix import paths, add loading/error/empty states
- **Layout, styling, and animations stay untouched**

Step 4 — Delete `src/design-handoff/` after all screens are ported. See `.gitignore` — this directory is a staging area, not committed.

---

## Breaking changes

If Claude Design's export format changes in a way that breaks this contract:

1. Update this file and bump the version at the top
2. Update `.cursor/skills/claude-design/SKILL.md` §Export Checklist
3. Update `/design verify` checks in `.cursor/commands/design.md`
4. Update Foundation Step 1–3 in `.cursor/commands/foundation.md`

All four files are the source of truth. Drift between them causes silent foundation failures.
