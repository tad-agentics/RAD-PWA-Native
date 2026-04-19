# Claude Design — Session Log ([App Name])

Per-session entries from Claude Design runs for **this app only**. Studio-wide patterns are promoted into `artifacts/studio/claude-design-log.md` after 2+ apps confirm them.

Append one entry per `/design`, `/design new-feature`, or `/design regen` session. Append-only — do not edit past entries.

---

## Entry format

Every entry has a **machine-parseable header block** followed by free-form notes. The header is required — `/session-end` and `/design` pre-flight read these fields to roll up prompt budget (H1) and detect Claude Design output-schema drift (H4). Do not omit fields; use `unknown` only when truly unmeasurable.

```
## [YYYY-MM-DD HH:mm] [phase | new-feature-[name] | regen-[screen]]

prompts_consumed: [N]            # H1 — integer count of Claude Design prompt turns this session
claude_design_version: [version | YYYY-MM-DD ship date | unknown]   # H4 — note product version shown in CD's about/footer; if unknown, log "unknown"
shape_mismatch: [yes | no]       # H4 — did /design verify or Foundation flag any handoff-shape deviation?
shape_mismatch_notes: [short]    # if yes — one line on what differed (e.g. "theme.css now uses @layer instead of @theme inline")
export_target: [src/design-handoff/ | src/design-handoff/new-feature-[name]/ | src/design-handoff/regen-[screen]/]
verification: [pass | fail-then-fixed-on-N | failed]

**What worked in the prompt:**
- [One-line note, e.g. "Pasting existing src/app.css token values in the brief prevented token drift"]

**What didn't:**
- [One-line note]

**Followup for studio log (if pattern repeats):**
- [One-line rule to promote to artifacts/studio/claude-design-log.md after next confirmation]
```

**Why these fields are mandatory:**

| Field | Used by | Consequence if missing |
|---|---|---|
| `prompts_consumed` | `/session-end` rollup, `/design` pre-flight quota guard | Studio discovers Claude Design rate-limit mid-build instead of warning at 40 turns / 30 days |
| `claude_design_version` + `shape_mismatch` | `/session-end` monthly review | Anthropic changes export schema → silent breakage across every new project until a human notices three sprints later |

---

## Entries

*No entries yet. First `/design` run on this app will append here.*
