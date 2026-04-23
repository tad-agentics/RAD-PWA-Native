# Example Handoff (Canonical v3)

**Purpose:** A minimal, correct design handoff for a 3-screen throwaway app ("Notebook"). Use this as the reference for what the canonical handoff shape looks like — what any adapter (`claude-design`, `manual`, `figma-make`, `stitch`, `figma-mcp`) must produce at `src/design-handoff/` to pass `/design verify`.

**Adapter-agnostic:** this example illustrates the shape at the contract layer. File structure, manifest schema, and `design-context.md` format are identical regardless of which tool produced the handoff. Tool-specific concerns (prompting patterns, discard lists, enforcement gates) live in each adapter's SKILL.md, not here.

**App concept (intentionally trivial):** Notebook. Three screens — a list of notes, a single note view, a settings screen. No backend, no auth, no monetization. The app is a vehicle for demonstrating the handoff *shape*, not a product to ship.

---

## What this teaches

The shape, naming, and conventions the canonical handoff uses when:
1. The repo is linked (token names match a known design system)
2. The brief is specific (every screen is actually generated, not skipped)
3. The adapter produces all required v3 artifacts (`handoff-manifest.json`, `design-context.md`, `theme.css`, components, screens)

If your first real handoff diverges substantially from this example, something went wrong — re-read `artifacts/docs/handoff-contract.md` and your active adapter's SKILL.md before proceeding to Foundation.

---

## File layout (mirrors `src/design-handoff/` after a real export)

```
example-handoff/
├── README.md                      ← this file
├── handoff-manifest.json.example  ← v3 manifest (metadata the adapter writes)
├── design-context.example.md      ← v3 design system doc (9 required H2 sections)
├── App.tsx                        ← entrypoint wiring all 3 screens (optional in v3)
├── theme.css                      ← CSS custom properties + @theme inline
├── components/
│   └── ui/                        ← 5 shared primitives
│       ├── button.tsx
│       ├── card.tsx
│       ├── input.tsx
│       ├── badge.tsx
│       └── dialog.tsx
└── screens/
    ├── notes-list.tsx             ← list of notes
    ├── note-detail.tsx            ← single note view + edit
    └── settings.tsx               ← settings screen
```

**This layout maps 1:1 to `artifacts/docs/handoff-contract.md` §Canonical handoff shape.** If your real handoff is missing any of these or has a different structure, the contract is broken.

---

## How to use this reference

### Picking an adapter

See `artifacts/design-tool.config.json` to select which adapter produces your project's handoff. Default is `claude-design`; escape hatch is `manual`. Each adapter's SKILL (`.cursor/skills/design-adapters/[name]/SKILL.md`) documents its specific workflow.

### Before your first `/design` run

Read `App.tsx`, `theme.css`, and one screen file (`notes-list.tsx`) to understand:
- How screens import from `@/components/ui/*`
- How `theme.css` declares CSS custom properties + `@theme inline` block
- How mock data is colocated with the screen (no fetch, no axios, no Supabase)
- What "production-shaped TSX" looks like at the handoff layer

Then review `handoff-manifest.example.json` and `design-context.example.md` — these two v3 additions are required at the root of every canonical handoff, and their shape is non-negotiable.

### After your first real `/design` run

Run `/design verify`. Then spot-check by hand:

- Token names in your `theme.css` follow the same role-keyed pattern (`--color-primary`, `--color-surface`, `--space-*`) as this example's
- Your `components/ui/` primitives have the same one-component-per-file structure
- Screen files declare their mock data inline (or in a sibling `mock-data.ts`), not by importing from a network module
- No `globals.css`, no `app/`, no `page.tsx` — Next.js conventions are forbidden per contract §Forbidden contents
- `handoff-manifest.json` validates against `artifacts/templates/handoff-manifest-schema.json`
- `design-context.md` has all 9 required H2 sections populated (Brand, Color System, Typography, Spacing, Components, Interaction Patterns, Anti-Patterns, Copy Rules, Build Constraints)

---

## Limitations of this reference

- **Not tool-generated.** This was hand-written to match the contract — not regenerated from any specific adapter. When a tool vendor ships a schema change (tracked by H4 in the active adapter), this example may need updating.
- **No data layer.** The example uses inline mock arrays. Real apps replace these with TanStack Query hooks against Supabase during Foundation. The transformation from mock-data to wired-data is documented in `frontend-data.mdc` and enforced by `/wire-check`.
- **No mobile.** This reference is web-only. For mobile/native handoffs, see the active adapter's SKILL.md §native-targeted brief (if supported) — output shape is similar but uses RN primitives.

---

## Maintenance

Update this reference if:
- The handoff contract bumps a major version (currently v3)
- A new adapter ships and produces materially different default output (e.g. a `figma-make-adapter` that differs enough to warrant a second example)
- A new mandatory file is added to the contract

Cost: one afternoon, once per contract version. Value: every new team member onboarding can compare against a known-good shape.
