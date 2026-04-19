# Claude Design — Handoff Notes ([App Name])

Supplementary metadata captured from Claude Design's **Claude Code handoff bundle** alongside the ZIP export. This file contains the structured implementation notes the ZIP does not include — brand tokens, component structure, and interaction guidance — so the Frontend agent reads intent, not just code.

Append-only. One section per Claude Design run. Initial build first, then new-feature appendices.

How to populate: after each `/design` run, the human pastes the relevant sections from Claude Code's handoff bundle (or transcribes the equivalent from Claude Design's "Hand off to Claude Code" panel) into the matching headings below. Do not edit past entries.

---

## Initial Build — [YYYY-MM-DD]

### Tokens

Paste the brand-token table from the handoff bundle here. Expected shape:

```
| Token | Value | Used in |
|---|---|---|
| --color-primary | hsl(...) | Button, Link, FocusRing |
| --color-surface | hsl(...) | Card, Dialog |
| --font-display | "..." | Headings |
| --space-1 / --space-2 / ... | rem | All spacing |
```

These should match `src/app.css` once Foundation copies `theme.css` into it.

### Components

Paste the component-structure summary. Expected shape:

```
| Component | Variants | Composes | Notes |
|---|---|---|---|
| Button | primary, secondary, ghost | (none) | size: sm/md/lg |
| Card | (none) | Surface | padding token: --space-4 |
| Dialog | modal, sheet | Surface, Button | trap focus, ESC closes |
```

### Notes

Implementation notes from the handoff bundle. Free-form. Examples:

- "Cards in `feed.tsx` use `--space-3` padding intentionally — tighter than dashboard cards."
- "The signup flow expects a 3-step modal — do not collapse to a single screen."

### Interactions

Interaction notes from the handoff. Free-form. Examples:

- "Settings → toggles fire on release, not press, to allow drag-undo."
- "Composer Cmd+Enter submits; Enter inserts a newline."

---

## Feature: [feature-name] — [YYYY-MM-DD]

(Append a new section per `/design new-feature [name]` run. Same headings.)

### Tokens

(only new tokens — do not repeat existing ones)

### Components

(only new components — do not repeat existing ones)

### Notes

### Interactions
