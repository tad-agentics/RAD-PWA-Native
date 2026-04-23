# Design Tool — Session Log ([App Name])

Per-session entries from every `/design` run on this app. Works with any adapter. Studio-wide patterns promoted to `artifacts/studio/design-tool-log.md` after 2+ apps confirm them.

Append one entry per `/design`, `/design new-feature`, or `/design regen` session. Append-only — do not edit past entries.

---

## Entry format

Every entry has a **machine-parseable header block** followed by free-form notes. The header is required — `/session-end` and `/design` pre-flight read these fields to roll up prompt budget (H1 — claude-design-adapter) and detect output-schema drift (H4). Do not omit fields; use `unknown` only when truly unmeasurable, or `n/a` when the field does not apply to the active adapter (e.g. `prompts_consumed: 0` for `manual-adapter`).

```
## [YYYY-MM-DD HH:mm] [initial | new-feature-[name] | regen-[screen]]

adapter: [claude-design | manual | figma-make | stitch | figma-mcp]
tool_version: [version or 'unknown' or 'n/a' for manual]
prompts_consumed: [N]            # H1 — integer count of design-tool prompt turns this session (0 for manual)
shape_mismatch: [yes | no]       # H4 — did /design verify or Foundation flag any handoff-shape deviation?
shape_mismatch_notes: [short]    # if yes — one line on what differed
export_target: [src/design-handoff/... path]
verification: [pass | fail-then-fixed-on-N | failed]

**What worked in the prompt:**
- [one-line note]

**What didn't:**
- [one-line note]

**Followup for studio log (if pattern repeats):**
- [one-line rule to promote to artifacts/studio/design-tool-log.md]
```

**Why these fields are mandatory:**

| Field | Used by | Consequence if missing |
|---|---|---|
| `adapter` | rollup scripts, /design pre-flight | rollup can't scope per-adapter trends (different adapters have different quota models) |
| `prompts_consumed` | `/session-end` rollup, `/design` pre-flight quota guard | Studio discovers design-tool rate-limit mid-build instead of warning at 40 turns / 30 days |
| `tool_version` + `shape_mismatch` | `/session-end` monthly review | Tool vendor changes export schema → silent breakage across every new project until a human notices three sprints later |

---

## Entries

*No entries yet. First `/design` run on this app will append here.*
