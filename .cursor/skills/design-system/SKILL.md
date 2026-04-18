---
name: design-system
description: Minimal design system reference for Claude Design projects. Produces a component inventory from Claude Design's handoff output and any EDS color/font summary needed for the Claude Design prompt guide. No token generation — Claude Design handles visual design. Read this when running /foundation to catalog Claude Design's components.
disable-model-invocation: true
---

# Design System — Claude Design Component Inventory

Claude Design handles visual design — colors, typography, spacing, component styling. There is no separate token extraction or theme generation step. This skill produces a component inventory from Claude Design's handoff output during Foundation.

**Output:** `artifacts/docs/design-system-spec.md` — component inventory only.

**Why this exists:** Product teams often add a **design system rules** layer so agents stop guessing. This skill produces a single inventory doc from **Claude Design's handoff output** that agents read before integrating screens or adding shared UI, so conventions stay consistent without re-prompting.

---

## When This Runs

During `/foundation`, before building screens. The Product Designer or Tech Lead catalogs Claude Design's output to give the Frontend Developer a clear component map.

## Process

1. **Read `src/design-handoff/`** — understand the full component tree from `App.tsx`

2. **Catalog `src/design-handoff/components/ui/`** — list every UI primitive Claude Design generated:
   - Component name, props, variants
   - Note: these move to `src/components/ui/` as-is during Foundation

3. **Identify gaps** — compare Claude Design's components against screen spec metadata:
   - Does Claude Design provide loading states? (Usually no — add `SkeletonCard`)
   - Does Claude Design provide error states? (Usually no — add `ErrorBanner`)
   - Does Claude Design provide empty states? (Usually no — add `EmptyState`)
   - Any other shared component needed by 2+ screens that Claude Design didn't generate?

4. **Extract color/font values** — scan Claude Design's Tailwind classes for the brand palette:
   - Primary colors used across components
   - Font families referenced
   - Claude Design typically defines these in a `theme.css` using CSS custom properties + Tailwind v4's `@theme inline`. Keep this CSS-based approach — copy into `src/app.css` during Foundation.

5. **Write `artifacts/docs/design-system-spec.md`**

## Output Format

````markdown
# Design System — [App Name]
**Source:** Claude Design handoff output

---

## Claude Design UI Components (src/components/ui/)

Moved from Claude Design as-is. Do not modify.

| Component | File | Props | Notes |
|---|---|---|---|
| Button | `button.tsx` | variant, size, disabled | Primary, secondary, ghost variants |
| Card | `card.tsx` | — | Container with padding |
| Dialog | `dialog.tsx` | open, onClose | Modal overlay |
| [catalog all from Claude Design...] | | | |

## Additional Shared Components (build in Foundation)

| Component | File | Required states | Why needed |
|---|---|---|---|
| `EmptyState` | `src/components/EmptyState.tsx` | with/without CTA | Claude Design has no empty states |
| `ErrorBanner` | `src/components/ErrorBanner.tsx` | with retry | Claude Design has no error states |
| `SkeletonCard` | `src/components/SkeletonCard.tsx` | shimmer | Claude Design has no loading states |
| [add only what's missing from Claude Design...] | | | |

## Brand Tokens (if Claude Design uses custom values)

Only document if Claude Design's output uses custom token values. Claude Design typically defines these in CSS custom properties via `@theme inline` — document the values here for reference, but keep them in CSS (do not migrate to `tailwind.config.ts`).

| Token | Value | Source |
|---|---|---|
| Primary color | `[value]` | Most frequent accent color in Claude Design's components |
| Font family | `[value]` | Font referenced in Claude Design's className strings |
````

---

## Quality Check

- Every Claude Design UI component cataloged
- Gap analysis complete — missing states identified
- No placeholder entries — all from actual Claude Design code
- Brand token values match what Claude Design's code actually uses
