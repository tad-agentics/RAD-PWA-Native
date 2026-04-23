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

## Required properties

| # | Property | Rule |
|---|---|---|
| 1 | Entrypoint | `App.tsx` or `routes.tsx` must wire every screen with resolvable routes |
| 2 | Theme | `theme.css` uses CSS custom properties + Tailwind v4 `@theme inline` (no `tailwind.config.ts`) |
| 3 | Primitives | `components/ui/` contains ≥ 5 files; each file exports one primitive |
| 4 | Screen coverage | Every screen in `artifacts/docs/screen-specs-[app]-v1.md` has a matching file |
| 5 | Mock data | Inline or colocated; **no** `fetch`, `axios`, `supabase`, or network calls |
| 6 | Imports | All relative imports resolve within the handoff bundle — no `@/` aliases pointing outside the bundle |
| 7 | Typography | `@font-face` declarations or Google Fonts `@import` in `theme.css` (Fonts will be self-hosted during Foundation) |
| 8 | Assets | Images referenced via imports or public URLs — no local `/public/` absolute paths |

---

## Forbidden contents

These cause `/design verify` to fail:

- `globals.css` — RAD uses `src/app.css`
- `app/` directory or `page.tsx` files — Next.js conventions, not React Router
- `next.config.*`, `next-env.d.ts` — Next.js config
- `node_modules/`, `package-lock.json`, `yarn.lock` — install happens in Foundation Step 0
- `src/make-import/`, `figma-make-brief.*` — legacy Figma Make tokens (validator guards against these)
- Any `.env*` files — secrets never flow through design handoff

## Discard list (Claude Design scaffold files — delete on import)

The Claude Design ZIP is "as Claude generated" — it ships with scaffold files that exist to make the prototype runnable inside Claude Design's preview, but have no place in the integrated codebase. `/design verify` flags these; the Frontend agent deletes them in Foundation Step 0 before installing dependencies.

| Pattern | Why discard |
|---|---|
| `index.html` at handoff root | RAD's React Router entry is generated by `react-router build`, not Claude Design |
| `vite.config.*` | RAD has its own locked `vite.config.ts` (do not let Claude Design's overwrite it) |
| `package.json` at handoff root | Foundation Step 0 reads imports across files and installs into the root `package.json` — never adopt Claude Design's version verbatim (it pins versions and includes its own dev deps) |
| `tsconfig*.json` at handoff root | Same — RAD has locked tsconfig for path aliases |
| `tailwind.config.*` | RAD uses Tailwind v4 with `@theme inline` in `src/app.css` — do not adopt a v3-style JS config |
| `postcss.config.*` | Tailwind v4 doesn't need it |
| `README.md` / `readme.md` at handoff root | Replace with RAD's README; do not preserve Claude Design's |
| `.gitignore`, `.eslintrc*`, `.prettierrc*` | RAD has its own (or intentionally none) |
| Any `*.stories.tsx` or Storybook config | RAD does not use Storybook |
| `public/vite.svg`, default React/Tailwind logos | Replace with the app's actual brand assets |
| Claude Design's stage/preview scaffold (e.g. `*-stage.js`, preview wrappers) | Internal to Claude Design's runtime |

If a file isn't on this list and isn't on the Required shape list, the Frontend agent asks the Tech Lead before keeping or discarding. New scaffold files appearing across exports get added to this list.

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
