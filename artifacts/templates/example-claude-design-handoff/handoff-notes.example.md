# Claude Design — Handoff Notes (Notebook example)

This is the **example** populated form of `artifacts/docs/claude-design-handoff-notes.md`. It exists as a comparison reference: when you run `verify-handoff-notes.sh` against your real entry, each `### ` subsection should be at least as substantive as what's below.

The C3 check enforces ≥ 20 real-content lines per subsection. This example clears that bar comfortably so reviewers can see what "good" looks like.

---

## Initial Build — 2026-04-19 14:30

prompts_consumed: 9
claude_design_version: 2026-04-17
shape_mismatch: no
shape_mismatch_notes:
export_target: src/design-handoff/
verification: pass

### Tokens

| Token | Value | Used in |
|---|---|---|
| `--color-background` | `oklch(0.985 0.005 95)` | body, page bg |
| `--color-foreground` | `oklch(0.18 0.015 95)` | body text, headings |
| `--color-surface` | `oklch(1 0 0)` | Card, Dialog panel |
| `--color-muted` | `oklch(0.96 0.005 95)` | Card border, Input border, ghost-button hover |
| `--color-muted-fg` | `oklch(0.45 0.01 95)` | secondary text, placeholder |
| `--color-primary` | `oklch(0.55 0.18 240)` | Button primary, focus ring, accent strokes |
| `--color-primary-fg` | `oklch(0.985 0.005 240)` | text on primary surfaces |
| `--color-accent` | `oklch(0.7 0.15 65)` | (reserved for tag highlights — not yet used in MVP) |
| `--color-success` | `oklch(0.65 0.16 145)` | success badge background, save confirmation |
| `--color-danger` | `oklch(0.6 0.22 25)` | delete button, destructive confirmation |
| `--color-warning` | `oklch(0.75 0.18 80)` | (reserved for low-storage warnings — post-MVP) |
| `--font-sans` | `"Inter", system-ui, sans-serif` | all body text |
| `--font-display` | `"Fraunces", Georgia, serif` | h1, h2, CardTitle |
| `--radius-sm` | `0.25rem` | Badge |
| `--radius-md` | `0.5rem` | Button, Input, Textarea |
| `--radius-lg` | `0.75rem` | Card, Dialog panel |
| `--space-1` | `0.25rem` | tightest icon padding, badge inset |
| `--space-2` | `0.5rem` | small gaps, button sm padding |
| `--space-3` | `0.75rem` | CardHeader margin, body line spacing |
| `--space-4` | `1rem` | Card default padding, list-item gap |
| `--space-6` | `1.5rem` | section gap, header bottom margin |
| `--space-8` | `2rem` | page-level vertical rhythm |

### Components

| Component | Variants | Composes | Notes |
|---|---|---|---|
| Button | primary, secondary, ghost, danger × sm/md/lg | — | rounded-md; primary uses --color-primary; danger only when destructive |
| Card | (none) | — | padding `--space-4`; `border` uses `--color-muted` |
| CardHeader | (none) | Card | `mb-3` baseline; pair with CardTitle |
| CardTitle | (none) | CardHeader | `font-display`, `text-lg`, `font-semibold` |
| CardBody | (none) | Card | wraps content; honors foreground color token |
| Input | (none) | — | h-10; full width; focus ring uses `--color-primary` |
| Textarea | (none) | — | min-h `6rem`; resize-y allowed; same border/focus as Input |
| Badge | neutral, success, warning, danger | — | text-xs; uses tone/15 alpha bg + solid foreground |
| Dialog | (none) | Button | `aria-modal=true`; ESC closes; backdrop click closes; focus trap NOT yet implemented (post-MVP) |
| (Empty/Loading/Error states) | — | Card | NOT generated — Foundation builds these as src/components/{EmptyState, SkeletonCard, ErrorBanner}.tsx |
| (Toast / Sonner) | — | — | NOT generated — Claude Design left it out; Foundation adds via shadcn Sonner if needed |
| (Avatar / User chip) | — | — | NOT generated — out of MVP scope for Notebook; defer to v2 |
| (Date picker) | — | — | NOT generated — Notebook MVP only displays save date, doesn't edit it |
| (Skeleton placeholders) | — | — | NOT generated — Foundation builds SkeletonCard since Claude Design omits loading states |
| (Tooltip) | — | — | NOT generated — kept out of MVP; persona finds tooltips noisy |
| (Dropdown / Select) | — | — | NOT generated; replaced by side-by-side Buttons (see Notes) |
| (Tabs) | — | — | NOT generated; not needed in 3-screen MVP |
| (Tag chip / multi-select) | — | — | NOT generated; tags are display-only via Badge in MVP |

### Notes

- Cards in `notes-list.tsx` are `role="button"` + `tabIndex={0}` so the entire card is the click target — copy expects the user to tap anywhere on the card to open. Do not collapse this to a "open" link in a corner; the whole-card affordance is intentional.
- `NotesListScreen` filters mocks client-side via `query.toLowerCase().includes(...)`. Foundation should preserve this UX (search-as-you-type, no submit) but route the filter through TanStack Query with `staleTime: 60_000` and a `useNotes(query)` hook. Do not switch to a debounced server search without UX review — the current responsiveness is the design intent.
- The "New note" floating button on the list screen routes to the detail screen with `noteId="new"` as a sentinel. Foundation should preserve the sentinel pattern; the detail screen branches on `isNew` to swap "Save" vs "Save changes" and to hide the Delete button until the note has been created.
- `NoteDetailScreen` shows `Saved YYYY-MM-DD` after a successful save. This date is intentionally low-resolution — do not "improve" it to a relative timestamp ("3 minutes ago") without checking with the EDS persona; the persona prefers calm, dateline-style information over real-time UI.
- Settings screen uses three side-by-side Buttons for theme rather than a Select. This is intentional — the persona is mobile-first and finds segmented controls easier than dropdowns. Do not "consolidate" to a Select control during integration.
- Save button is disabled-not-hidden when title is empty. The disabled state is part of the "you must name the note first" affordance; replacing with a hidden button removes the visual hint that Save exists.
- Delete button on the detail screen lives in the header next to Save, not inline with the body. Header placement signals destructive action requires intent (move pointer up to header) rather than an accidental in-body tap.
- Mock data IDs (`n1`, `n2`, …) are intentionally short. When wiring Supabase, switch to UUIDs but do NOT expose UUIDs in URLs — use a slug column on the table and reference `/note/[slug]` in the route. Foundation's wiring map handles this transformation.
- Settings screen's Free/Upgrade card is intentionally bottom of the stack — visible without scrolling on mobile but not the focus. Do not move to the top during integration; the persona finds upgrade-first patterns aggressive.
- All page containers use `max-w-2xl mx-auto p-6` as the outer wrapper. Foundation should preserve this wrapper as a `<PageContainer>` shared component if more screens repeat the pattern, but do not break responsive behavior — it's deliberately narrow on desktop to maintain reading-line length consistent with the EDS persona.
- Save state intentionally has no spinner. The persona's mental model is "save = done"; an asynchronous spinner introduces uncertainty Foundation should preserve by making the mutation optimistic (UI updates first, server confirms in background, rollback on error).
- Tag values (`work`, `personal`) are hardcoded in the mock and rendered via Badge tone. When Foundation adds a tags column, restrict the enum at the DB layer; do not expose a free-text tag input in MVP — the persona prefers the constraint.
- `notes-list.tsx` has no pagination. MVP assumes ≤ 50 notes per user. When Foundation reaches 50+, add pagination via TanStack Query infinite scroll with cursor on `updated_at DESC` — do not switch to numbered pages.
- The detail screen's auto-route on save (back to list after Save) is a future enhancement, not MVP behavior. Current MVP keeps the user on the detail screen with the updated `Saved YYYY-MM-DD` indicator. Don't change without persona review.
- Settings screen shows "Free" badge for the plan. When Foundation wires real billing, the badge tone should change with plan tier: neutral for Free, success for Pro, warning for Past-due. Use `tone="warning"` not red — past-due is recoverable, not a destructive state.
- Empty state copy ("No notes match. Clear the search or start a new note.") is intentionally action-oriented, not apologetic. EDS rule §Forbidden Patterns prohibits "Sorry," "Oops," "Hmm" openings. Preserve.
- The Card hover ring color is `border-primary/40` (40% opacity primary). Do not change to a separate hover token; the muted primary ring is the visual identity for "interactive card surface."
- Dialog backdrop is `bg-foreground/40` (40% opacity foreground), NOT `bg-black/50`. The token-based color adapts when dark mode ships in v2 without rework. Preserve token usage.
- "Upgrade" button on Settings opens nothing in MVP. Foundation wires this to a Stripe Checkout session via Edge Function. Do not show a confirm dialog before redirect — direct redirect to Stripe is the pattern.
- Title and Body fields on the detail screen accept emoji and pasted-rich-text but render as plain text only. Do not introduce a rich-text editor in MVP; v2 may add Markdown support but persona has not requested it.

### Interactions

- Search input on the list screen: focus + type triggers filter immediately. No `Enter` submit, no debounce. Backspace down to empty restores the full list — empty-state copy below the input does not flash; transition is instant.
- Tapping a card on the list screen navigates to the detail screen with the card's note ID. The whole card surface is the target (not just the title).
- Detail screen's `Save` button is disabled until the title is non-empty after `.trim()`. Body may be empty.
- `Cmd+S` does NOT save in this MVP. Add post-MVP if requested — wire to the same handler as the Save button. Document keyboard support in the public-facing release notes if added.
- `Esc` closes the Delete confirmation dialog. Backdrop click also closes. Both paths return focus to the previously-focused element (post-MVP — current MVP releases focus to body).
- `Esc` does NOT close the detail-screen view (would lose unsaved changes silently). Back button is the only exit.
- Theme toggle on Settings is non-persistent in the MVP — refresh resets to "system". Foundation wires this to `localStorage` + `next-themes`-equivalent during integration.
- Tab order on the detail screen: Back → Delete → Save → Title → Body. Skip-to-Save is intentional so keyboard-first users can save without traversing the body field.
- The "New note" floating button has its own tab stop after the last list card. Visible focus ring uses `--color-primary` — not customized; matches Button focus behavior.
- Long titles in the list view truncate at one line via `text-overflow: ellipsis` (handled by parent flex layout, not on the title element). The full title still appears on the detail screen — no truncation there.
- Card hover state is subtle (`border-primary/40` instead of full primary). On touch devices the hover never triggers; do not add tap-feedback animation — the navigation transition itself is the feedback.
- Dialog open animation: instant in MVP. Do not introduce a fade-in without persona review — the persona finds modal animations annoying for confirmation prompts.
- Settings theme buttons swap variant immediately on click; no async state. When wiring real persistence, treat the click as optimistic (update UI first, persist asynchronously) with rollback on storage error.
- Floating "New note" button stays in the bottom-right at all scroll positions (`position: fixed`). Touch-target size is 48×48 minimum (the `lg` button size satisfies this). Do not shrink to `md` size on mobile.
- Search input does NOT clear on screen exit. Coming back from the detail screen returns the user to the same filtered list. This is intentional — the persona reads "back" as "back to where I was," not "back to a fresh state."
- Detail screen's body Textarea uses `resize-y` only (vertical), not `resize` (both axes). Horizontal resize would break the page layout. Preserve.
- Theme toggle on Settings is keyboard-accessible (Tab → arrow not used; each option is its own Tab stop). Don't switch to a single roving tabindex without persona review — explicit Tab stops are easier for the persona to discover.
- Settings page's three Card sections are vertically stacked with `space-y-4`. Do not combine into a single Card — the visual chunking helps the persona scan; one big Card flattens the hierarchy.
- The empty Settings spacer (`<div className="w-16" />`) in the header is intentional — keeps the title centered when the Back button is the only left-side element. Foundation should preserve symmetric headers on screens with a back affordance.

---

## Feature: shared-notes — 2026-05-03 11:15

prompts_consumed: 4
claude_design_version: 2026-05-01
shape_mismatch: no
export_target: src/design-handoff/new-feature-shared-notes/
verification: pass

### Tokens

(no new tokens — feature reuses existing palette)

### Components

(no new primitives — feature uses existing Button, Card, Input, Badge, Dialog)

### Notes

(would be filled with Claude Code handoff notes for the shared-notes feature here…)

### Interactions

(would be filled with interaction notes for the shared-notes feature here…)
