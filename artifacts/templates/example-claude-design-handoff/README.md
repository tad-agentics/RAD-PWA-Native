# Example Claude Design Handoff — Reference

**Purpose:** A minimal, correct Claude Design handoff for a 3-screen throwaway app ("Notebook"). Use this as the reference when reviewing your first real Claude Design export — compare shape, file layout, token naming, mock-data structure, and import patterns against this example.

**App concept (intentionally trivial):** Notebook. Three screens — a list of notes, a single note view, a settings screen. No backend, no auth, no monetization. The app is a vehicle for demonstrating the handoff *shape*, not a product to ship.

---

## What this teaches

The shape, naming, and conventions Claude Design produces when:
1. The repo is linked (token names match a known design system)
2. The brief is specific (every screen is actually generated, not skipped)
3. The handoff bundle is properly captured alongside the ZIP

If your first real handoff diverges substantially from this example, something went wrong — re-read `.cursor/skills/claude-design/SKILL.md` and `artifacts/docs/handoff-contract.md` before proceeding to Foundation.

---

## File layout (mirrors `src/design-handoff/` after a real export)

```
example-claude-design-handoff/
├── README.md                      ← this file
├── App.tsx                        ← entrypoint wiring all 3 screens
├── theme.css                      ← CSS custom properties + @theme inline
├── components/
│   └── ui/                        ← 5 shared primitives
│       ├── button.tsx
│       ├── card.tsx
│       ├── input.tsx
│       ├── badge.tsx
│       └── dialog.tsx
├── screens/
│   ├── notes-list.tsx             ← list of notes
│   ├── note-detail.tsx            ← single note view + edit
│   └── settings.tsx               ← settings screen
└── handoff-notes.example.md       ← example of the Claude Code handoff metadata
```

**This layout maps 1:1 to the contract in `artifacts/docs/handoff-contract.md` §Required shape.** If your real handoff is missing any of these or has a different structure, the contract is broken.

---

## How to use this reference

### Before your first Claude Design run

Read `App.tsx`, `theme.css`, and one screen file (`notes-list.tsx`) to understand:
- How screens import from `@/components/ui/*`
- How `theme.css` declares CSS custom properties + `@theme inline` block
- How mock data is colocated with the screen (no fetch, no axios, no Supabase)
- What "production-shaped TSX" looks like for Claude Design output

### After your first real Claude Design run

Run `/design verify` (which invokes the C2/C3/H3 scripts). Then spot-check by hand:

- Token names in your `theme.css` follow the same role-keyed pattern (`--color-primary`, `--color-surface`, `--space-*`) as this example's
- Your `components/ui/` primitives have the same one-component-per-file structure
- Screen files declare their mock data inline (or in a sibling `mock-data.ts`), not by importing from a network module
- No `globals.css`, no `app/`, no `page.tsx` — Next.js conventions are forbidden

### When verifying handoff-notes.md

`handoff-notes.example.md` shows what a populated `artifacts/docs/claude-design-handoff-notes.md` entry looks like — Tokens table, Components table, Notes bullets, Interactions bullets, each substantial enough to clear the C3 ≥ 20-line threshold. Compare your real entry against this; if yours is shorter, paste more from Claude Code's handoff bundle.

---

## Limitations of this reference

- **No real Claude Design output.** This was hand-written to match the contract — not regenerated from Claude Design itself. When Anthropic ships schema changes (H4), this example may need updating. Watch for `shape_mismatch: yes` streaks in `claude-design-log.md`.
- **No data layer.** The example uses inline mock arrays. Real apps replace these with TanStack Query hooks against Supabase during Foundation. The transformation from mock-data to wired-data is documented in `frontend-data.mdc` and enforced by `/wire-check`.
- **No mobile.** This reference is web-only. For mobile/native handoffs, see `claude-design/SKILL.md` §2b (native-targeted brief) — output shape is similar but uses RN primitives.

---

## Maintenance

Update this reference if:
- The handoff contract bumps a major version (currently v2)
- Anthropic changes Claude Design's default export schema in a way that propagates to all new exports
- A new mandatory file is added to the contract

Cost: one afternoon, once per contract version. Value: every new team member onboarding can compare against a known-good shape.
