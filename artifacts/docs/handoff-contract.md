# Claude Design → RAD Handoff Contract

This is the file-level contract between Claude Design (the design tool) and RAD (the integration pipeline). If an export does not meet this contract, `/design verify` fails and the handoff is rejected before `/foundation` or `/feature` run.

Contract version: 2 (dual-export — ZIP + Claude Code handoff metadata). Update the version if the shape changes in a breaking way.

---

## Two artifacts, one handoff

Claude Design exports along several paths. RAD consumes **two**:

| Artifact | Source path | Used for |
|---|---|---|
| **ZIP** (extracted) | `src/design-handoff/` | Source of truth for code — Frontend agent copy-then-edits files from here |
| **Claude Code handoff metadata** (manually captured) | `artifacts/docs/claude-design-handoff-notes.md` | Implementation notes, brand tokens, component-structure summary, interaction notes — supplementary context the Frontend agent reads alongside the code |

The ZIP is what RAD's pipeline runs on. The handoff metadata is captured because Anthropic's Claude Code handoff bundle includes structured implementation notes the ZIP does NOT contain — those notes prevent ambiguity during integration. Without them, the Frontend agent has to infer intent from raw code.

The other Claude Design exports (HTML, PPTX, PDF, Canva) are not used by RAD.

### Repo link is mandatory

Before generating either artifact, the human must connect the repo to Claude Design via Import → GitHub or Local Directory. Without the link:
- Claude Design invents new brand tokens instead of matching `src/app.css`
- Primitives in `src/components/ui/` get duplicated under different names
- Output drifts further from the existing system on every run

`/design` pre-flight rejects an export that was generated without a linked repo. The Product Designer can verify by spot-checking that token names in `theme.css` match `src/app.css` token names exactly (post-Foundation only).

---

## Required shape

### Initial build — `src/design-handoff/`

```
src/design-handoff/
├── App.tsx                     (or routes.tsx) — entrypoint wiring every screen
├── theme.css                   — CSS custom properties + @theme inline (Tailwind v4)
├── components/
│   └── ui/                     — shared UI primitives (Button, Card, Dialog, …)
│       └── [≥ 5 primitive files]
├── components/
│   └── [app-level shared components, optional — e.g. ScreenHeader, CreditGate]
├── routes/ or screens/         — one file per screen in screen-specs-[app]-v1.md
│   └── [screen].tsx
└── mock-data/                  (optional, or inline) — hardcoded entity mocks
```

### Incremental — `src/design-handoff/new-feature-[name]/`

```
src/design-handoff/new-feature-[name]/
├── routes/ or screens/
│   └── [screen].tsx            — only the new screens for this feature
└── mock-data/                  — only mocks for new entities, if any
```

**Must not contain** `components/ui/` — primitives are locked after Foundation.

### Drift regen — `src/design-handoff/regen-[screen]/`

```
src/design-handoff/regen-[screen]/
└── [screen].tsx                — single-file regen, mock-data shape preserved
```

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
