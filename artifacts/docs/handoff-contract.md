# Claude Design → RAD Handoff Contract

This is the file-level contract between Claude Design (the design tool) and RAD (the integration pipeline). If an export does not meet this contract, `/design verify` fails and the handoff is rejected before `/foundation` or `/feature` run.

Contract version: 1. Update the version if the shape changes in a breaking way.

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
