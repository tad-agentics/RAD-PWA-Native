#!/bin/bash
# Claude Design Prompt-Budget + Version-Drift Rollup — H1 + H4
#
# Reads structured header blocks from artifacts/docs/claude-design-log.md
# (and optionally the studio log) and reports:
#
#   H1 — Prompt budget:
#     - 30-day rolling sum of `prompts_consumed`
#     - WARN threshold: ≥ 40 turns (note in /design pre-flight)
#     - BLOCK threshold: ≥ 50 turns (refuse new /design until budget resets
#       or Tech Lead approves an override)
#
#   H4 — Output-schema drift:
#     - Counts consecutive recent entries flagged `shape_mismatch: yes`
#     - At 3 consecutive: prompts opening a contract-v3 issue
#     - Lists `claude_design_version` values seen so the human can correlate
#
# Header block format (set by claude-design-log.md template):
#
#   ## YYYY-MM-DD HH:mm  [optional context]
#
#   prompts_consumed: 7
#   claude_design_version: 2026-04-30 | 1.2.0 | unknown
#   shape_mismatch: no
#   shape_mismatch_notes: ...
#   export_target: ...
#   verification: pass
#
# Usage:
#   bash rollup-prompt-budget.sh
#   bash rollup-prompt-budget.sh --machine     # parseable single-line output
#   bash rollup-prompt-budget.sh path/to/log.md
#
# Exit codes:
#   0 — under WARN
#   1 — at/over BLOCK threshold OR shape-mismatch streak >= 3
#   2 — at WARN but under BLOCK
#   3 — usage / log missing

set -e

WARN_THRESHOLD=40
BLOCK_THRESHOLD=50
DRIFT_STREAK_TRIGGER=3
WINDOW_DAYS=30

MACHINE=0
LOG_FILE="artifacts/docs/claude-design-log.md"

for arg in "$@"; do
  case "$arg" in
    --machine) MACHINE=1 ;;
    -*)
      echo "usage: $0 [--machine] [log-file]" >&2
      exit 3
      ;;
    *) LOG_FILE="$arg" ;;
  esac
done

if [ ! -f "$LOG_FILE" ]; then
  echo "rollup: log file not found: $LOG_FILE" >&2
  exit 3
fi

# Parse the log: each entry header is a `## YYYY-MM-DD ...` line; fields are
# `key: value` lines that follow until the next `##` heading or `---` divider.
# We accept entries where the date is within WINDOW_DAYS of today.

TODAY_EPOCH=$(date +%s)
WINDOW_EPOCH=$(( TODAY_EPOCH - WINDOW_DAYS * 86400 ))

# awk does the heavy lifting — emits one line per entry as a TSV:
#   epoch \t prompts_consumed \t claude_design_version \t shape_mismatch
# Skip the entry-format example block (between ``` fences).
ENTRIES_TSV=$(awk -v win="$WINDOW_EPOCH" '
  BEGIN { in_fence = 0; in_entry = 0 }

  # Track fenced code blocks — ignore content inside (template example)
  /^```/ { in_fence = !in_fence; next }
  in_fence { next }

  # New entry header — flush previous, start new
  /^## [0-9]{4}-[0-9]{2}-[0-9]{2}/ {
    if (in_entry) emit()
    in_entry = 1
    date_str = $2
    prompts = -1
    version = "unknown"
    mismatch = "no"
    next
  }

  # Section divider also closes an entry
  /^---$/ {
    if (in_entry) { emit(); in_entry = 0 }
    next
  }

  # Field lines inside an entry
  in_entry && /^prompts_consumed:[[:space:]]*[0-9]+/ {
    n = $0; sub(/^prompts_consumed:[[:space:]]*/, "", n); prompts = n + 0
  }
  in_entry && /^claude_design_version:/ {
    v = $0; sub(/^claude_design_version:[[:space:]]*/, "", v)
    sub(/[[:space:]]*#.*$/, "", v)   # strip trailing # comment
    if (v != "") version = v
  }
  in_entry && /^shape_mismatch:[[:space:]]*(yes|no)/ {
    m = $0; sub(/^shape_mismatch:[[:space:]]*/, "", m)
    sub(/[[:space:]]*#.*$/, "", m)
    mismatch = m
  }

  END { if (in_entry) emit() }

  function emit(    cmd, epoch, line) {
    if (prompts < 0) return  # entry without machine fields — skip
    cmd = "date -d \"" date_str "\" +%s 2>/dev/null || date -j -f \"%Y-%m-%d\" \"" date_str "\" +%s 2>/dev/null"
    cmd | getline epoch
    close(cmd)
    if (epoch + 0 < win) return
    print epoch "\t" prompts "\t" version "\t" mismatch
  }
' "$LOG_FILE")

# Compute totals
TOTAL_PROMPTS=0
ENTRY_COUNT=0
VERSIONS_SEEN=""
# For drift streak: walk entries in chronological-recency order (newest first),
# count consecutive `yes` from the most recent entry.
RECENT_FIRST=$(echo "$ENTRIES_TSV" | sort -rn -k1,1)
DRIFT_STREAK=0
DRIFT_BROKEN=0

while IFS=$'\t' read -r epoch prompts version mismatch; do
  [ -z "$epoch" ] && continue
  TOTAL_PROMPTS=$(( TOTAL_PROMPTS + prompts ))
  ENTRY_COUNT=$(( ENTRY_COUNT + 1 ))
  case " $VERSIONS_SEEN " in
    *" $version "*) ;;
    *) VERSIONS_SEEN="$VERSIONS_SEEN $version" ;;
  esac
  if [ "$DRIFT_BROKEN" -eq 0 ]; then
    if [ "$mismatch" = "yes" ]; then
      DRIFT_STREAK=$(( DRIFT_STREAK + 1 ))
    else
      DRIFT_BROKEN=1
    fi
  fi
done <<< "$RECENT_FIRST"

# Determine status
if [ "$TOTAL_PROMPTS" -ge "$BLOCK_THRESHOLD" ] || [ "$DRIFT_STREAK" -ge "$DRIFT_STREAK_TRIGGER" ]; then
  STATUS="BLOCK"
  EXIT=1
elif [ "$TOTAL_PROMPTS" -ge "$WARN_THRESHOLD" ]; then
  STATUS="WARN"
  EXIT=2
else
  STATUS="OK"
  EXIT=0
fi

if [ "$MACHINE" -eq 1 ]; then
  printf 'status=%s window_days=%d entries=%d prompts_consumed=%d warn=%d block=%d drift_streak=%d versions=%s\n' \
    "$STATUS" "$WINDOW_DAYS" "$ENTRY_COUNT" "$TOTAL_PROMPTS" "$WARN_THRESHOLD" "$BLOCK_THRESHOLD" "$DRIFT_STREAK" "$(echo "$VERSIONS_SEEN" | sed 's/^ *//;s/ *$//;s/ /,/g')"
  exit "$EXIT"
fi

# Human-readable
cat <<EOF
═════════════════════════════════════════════════════════
Claude Design rollup — last $WINDOW_DAYS days  (status: $STATUS)
═════════════════════════════════════════════════════════
Source: $LOG_FILE
Entries in window: $ENTRY_COUNT
Total prompts_consumed: $TOTAL_PROMPTS  (warn ≥ $WARN_THRESHOLD, block ≥ $BLOCK_THRESHOLD)
Consecutive shape_mismatch (most-recent first): $DRIFT_STREAK / $DRIFT_STREAK_TRIGGER
Claude Design versions seen:$VERSIONS_SEEN
EOF

if [ "$TOTAL_PROMPTS" -ge "$BLOCK_THRESHOLD" ]; then
  cat <<EOF

⛔ BLOCK — prompt budget exceeded.

The rolling 30-day count of Claude Design prompt turns is $TOTAL_PROMPTS, at or
above the block threshold of $BLOCK_THRESHOLD. Continuing risks Anthropic
rate-limiting mid-build.

Options:
  1. Wait for the 30-day window to roll forward (oldest entries age out).
  2. Tech Lead override: log a justification in claude-design-log.md and
     reset by archiving older entries to artifacts/studio/claude-design-log.md.
  3. Split the next sprint across two studio accounts if quota is hard.
EOF
elif [ "$TOTAL_PROMPTS" -ge "$WARN_THRESHOLD" ]; then
  cat <<EOF

⚠️  WARN — approaching prompt budget.

You are at $TOTAL_PROMPTS / $BLOCK_THRESHOLD turns in the rolling $WINDOW_DAYS-day
window. /design pre-flight will surface this warning until the count drops.
Plan upcoming runs accordingly — bigger briefs, fewer iterations.
EOF
fi

if [ "$DRIFT_STREAK" -ge "$DRIFT_STREAK_TRIGGER" ]; then
  cat <<EOF

⛔ BLOCK — Claude Design output-schema drift detected.

The last $DRIFT_STREAK consecutive entries were flagged shape_mismatch: yes.
Anthropic likely changed Claude Design's export schema (theme.css shape,
components/ui/ layout, or handoff-bundle structure).

Action:
  1. Open an issue: artifacts/issues/handoff-contract-v3.md
  2. Document the new shape vs. handoff-contract.md v2
  3. Update artifacts/docs/handoff-contract.md → bump to v3
  4. Update .cursor/skills/claude-design/scripts/verify-handoff-tokens.sh
     and verify-handoff-notes.sh as needed
  5. Re-run /design verify on the affected handoffs
EOF
fi

exit "$EXIT"
