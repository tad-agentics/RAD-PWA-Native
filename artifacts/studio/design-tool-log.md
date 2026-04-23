# Design Tool — Studio-Wide Learnings

Patterns confirmed across 2+ apps get promoted here from per-app `artifacts/docs/design-tool-log.md` files. Rules become doctrine once documented here.

Read this before writing any new `design-brief.md`, regardless of which adapter is active.

---

## Entry format

Promoted from per-app entries (`artifacts/docs/design-tool-log.md`) at `/session-end` once a pattern is observed across 2+ apps. Header block is machine-parseable — same field names as the per-app log so the rollup script can ingest both for monthly studio review.

```
### [YYYY-MM-DD] [app-slug] — [phase/feature]

adapter: [claude-design | manual | figma-make | stitch | figma-mcp]
prompts_consumed: [N]            # H1 — sum across this app's run for the entry context
tool_version: [version | YYYY-MM-DD ship date | unknown | n/a]   # H4
shape_mismatch: [yes | no]       # H4 — set yes if /design verify or Foundation flagged any handoff-shape deviation during this app
result: [clean | required-regen | failed]

**What worked:**
- [One-line pattern. Example: "Listing mock entities at top of brief produced consistent data shapes across all screens."]

**What didn't:**
- [One-line failure. Example: "Asking for 20 screens in one prompt → the tool skipped 3 — split next time."]

**Takeaway for next ship:**
- [One-line rule. Example: "Cap briefs at 12 screens per run; split by wave."]
```

---

## Entries

*No entries yet. First app shipped will seed this log.*

---

## Consolidated rules (updated as patterns repeat)

These are promoted from entry-level notes to studio-wide rules once 2+ apps prove them. Read this section before writing any new brief.

- _(empty — promote rules here after observing 2+ confirmations)_

---

## Failure-mode checklist

Before starting a new design-tool session, verify none of these past failure modes apply to the current brief. Each bullet is preventable if caught before prompting.

- _(empty — will populate as failures are logged)_
