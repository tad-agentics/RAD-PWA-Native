---
name: design-system
description: Minimal design system reference for adapter-produced projects. Produces a component inventory from the adapter's handoff output and any EDS color/font summary needed for the design brief. No token generation — the design tool handles visual design. Read this when running /foundation to catalog the adapter's components.
disable-model-invocation: true
---

# Design System — Handoff Component Inventory

The configured design tool handles visual design — colors, typography, spacing, component styling. There is no separate token extraction or theme generation step. This skill produces a component inventory from the adapter's handoff output during Foundation.

**Output:** `artifacts/docs/design-system-spec.md` — component inventory only.

**Why this exists:** Product teams often add a **design system rules** layer so agents stop guessing. This skill produces a single inventory doc from **the adapter's handoff output** that agents read before integrating screens or adding shared UI, so conventions stay consistent without re-prompting.

---

## When This Runs

During `/foundation`, before building screens. The Product Designer or Tech Lead catalogs the adapter's output to give the Frontend Developer a clear component map.

## Process

1. **Read `src/design-handoff/`** — understand the full component tree from `App.tsx`

2. **Catalog `src/design-handoff/components/ui/`** — list every UI primitive the adapter generated:
   - Component name, props, variants
   - Note: these move to `src/components/ui/` as-is during Foundation

3. **Identify gaps** — compare the adapter's components against screen spec metadata:
   - Does the handoff provide loading states? (Usually no — add `SkeletonCard`)
   - Does the handoff provide error states? (Usually no — add `ErrorBanner`)
   - Does the handoff provide empty states? (Usually no — add `EmptyState`)
   - Any other shared component needed by 2+ screens that the adapter didn't generate?

4. **Extract color/font values** — scan the handoff's Tailwind classes for the brand palette:
   - Primary colors used across components
   - Font families referenced
   - The adapter typically writes these in a `theme.css` using CSS custom properties + Tailwind v4's `@theme inline`. Keep this CSS-based approach — copy into `src/app.css` during Foundation.

5. **Write `artifacts/docs/design-system-spec.md`**

## Output Format

````markdown
# Design System — [App Name]
**Source:** handoff output

---

## Handoff UI Components (src/components/ui/)

Moved from the handoff as-is. Do not modify.

| Component | File | Props | Notes |
|---|---|---|---|
| Button | `button.tsx` | variant, size, disabled | Primary, secondary, ghost variants |
| Card | `card.tsx` | — | Container with padding |
| Dialog | `dialog.tsx` | open, onClose | Modal overlay |
| [catalog all from the handoff...] | | | |

## Additional Shared Components (build in Foundation)

| Component | File | Required states | Why needed |
|---|---|---|---|
| `EmptyState` | `src/components/EmptyState.tsx` | with/without CTA | the handoff has no empty states |
| `ErrorBanner` | `src/components/ErrorBanner.tsx` | with retry | the handoff has no error states |
| `SkeletonCard` | `src/components/SkeletonCard.tsx` | shimmer | the handoff has no loading states |
| [add only what's missing from the handoff...] | | | |

## Brand Tokens (if the adapter uses custom values)

Only document if the adapter's output uses custom token values. The adapter typically defines these in CSS custom properties via `@theme inline` — document the values here for reference, but keep them in CSS (do not migrate to `tailwind.config.ts`).

| Token | Value | Source |
|---|---|---|
| Primary color | `[value]` | Most frequent accent color in the adapter's components |
| Font family | `[value]` | Font referenced in the handoff's className strings |
````

---

## Quality Check

- Every handoff UI component cataloged
- Gap analysis complete — missing states identified
- No placeholder entries — all from actual handoff code
- Brand token values match what the handoff's code actually uses
