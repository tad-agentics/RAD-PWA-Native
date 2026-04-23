#!/bin/bash
# Handoff Metadata Capture Check — C3 enforcement
#
# The Claude Code handoff bundle carries implementation notes, brand tokens,
# component structure, and interaction guidance that the ZIP does not include.
# Capture lives in artifacts/docs/design-context.md as
# human-pasted sections. Previously, /design verify only asked "is the file
# not blank?" — a single word passed. In practice Frontend agents received
# sparse metadata and invented design intent silently.
#
# This script enforces the paste budget (~5 minutes):
#   - Four required subsections under the target entry: Tokens, Components,
#     Notes, Interactions
#   - Each subsection must have ≥ 20 lines of real content (blank lines and
#     known template placeholders do not count)
#
# Usage:
#   bash verify-handoff-notes.sh initial
#   bash verify-handoff-notes.sh new-feature [name]
#   bash verify-handoff-notes.sh initial  custom/notes-file.md   # override path
#
# Exit codes:
#   0 — PASS (all 4 subsections meet the minimum)
#   1 — BLOCKING (one or more subsections under-populated or missing)
#   2 — USAGE / WARN

set -e

MODE="${1:-}"
ARG2="${2:-}"
ARG3="${3:-}"

NOTES_FILE="artifacts/docs/design-context.md"
ENTRY_KEY=""

case "$MODE" in
  initial)
    # `initial [notes-file]`
    [ -n "$ARG2" ] && NOTES_FILE="$ARG2"
    ENTRY_HEADER_PREFIX="## Initial Build"
    ENTRY_LABEL="Initial Build"
    ;;
  new-feature)
    # `new-feature <name> [notes-file]`
    if [ -z "$ARG2" ]; then
      echo "usage: $0 new-feature <feature-name> [notes-file]" >&2
      exit 2
    fi
    ENTRY_KEY="$ARG2"
    [ -n "$ARG3" ] && NOTES_FILE="$ARG3"
    ENTRY_HEADER_PREFIX="## Feature: $ENTRY_KEY"
    ENTRY_LABEL="Feature: $ENTRY_KEY"
    ;;
  *)
    echo "usage: $0 <initial|new-feature> [name] [notes-file]" >&2
    echo "  initial                          — validate the '## Initial Build' entry" >&2
    echo "  new-feature <feature-name>       — validate the '## Feature: <name>' entry" >&2
    exit 2
    ;;
esac

if [ ! -f "$NOTES_FILE" ]; then
  echo "BLOCKING: $NOTES_FILE missing — handoff-notes file was never created" >&2
  exit 1
fi

# Extract the target entry block — from its `## ` header through to the next
# `## ` header or EOF.
ENTRY=$(awk -v prefix="$ENTRY_HEADER_PREFIX" '
  BEGIN { capture = 0 }
  index($0, prefix) == 1 { capture = 1; print; next }
  /^## / && capture      { exit }
  capture                { print }
' "$NOTES_FILE")

if [ -z "$ENTRY" ]; then
  cat >&2 <<EOF
BLOCKING: no '$ENTRY_HEADER_PREFIX' heading found in $NOTES_FILE

Expected a Markdown heading like:
  $ENTRY_HEADER_PREFIX — YYYY-MM-DD

followed by four '### ' subsections: Tokens, Components, Notes, Interactions.
EOF
  exit 1
fi

MIN_LINES=20
FAILURES=()

for SECTION in Tokens Components Notes Interactions; do
  SECTION_HEADER="### $SECTION"

  CONTENT=$(echo "$ENTRY" | awk -v sec="$SECTION_HEADER" '
    BEGIN { capture = 0 }
    $0 == sec                  { capture = 1; next }
    /^### / && capture         { exit }
    /^## /  && capture         { exit }
    capture                    { print }
  ')

  if [ -z "$CONTENT" ]; then
    FAILURES+=("'$SECTION_HEADER' subsection missing or empty")
    continue
  fi

  # Count lines that are NOT blank AND NOT known template placeholders.
  # Template placeholders = the boilerplate sentences from the default
  # handoff-notes template. If they are still present, the section was not
  # populated with real handoff content.
  REAL_LINES=$(printf '%s\n' "$CONTENT" \
    | grep -Ev '^[[:space:]]*$' \
    | grep -Ev 'Paste the brand-token table from the handoff bundle here' \
    | grep -Ev 'Paste the component-structure summary' \
    | grep -Ev 'Implementation notes from the handoff bundle' \
    | grep -Ev 'Interaction notes from the handoff' \
    | grep -Ev 'Free-form\. Examples:' \
    | grep -Ev 'These should match `src/app\.css`' \
    | grep -Ev '^\(only new tokens' \
    | grep -Ev '^\(only new components' \
    | grep -Ev '^\(Append a new section' \
    | wc -l | tr -d ' ')

  if [ "$REAL_LINES" -lt "$MIN_LINES" ]; then
    FAILURES+=("'$SECTION_HEADER' has only $REAL_LINES real content line(s), need ≥ $MIN_LINES")
  fi
done

if [ ${#FAILURES[@]} -gt 0 ]; then
  {
    echo "BLOCKING: handoff-notes capture for '$ENTRY_LABEL' is under-populated."
    echo ""
    echo "Failures:"
    for f in "${FAILURES[@]}"; do
      echo "  - $f"
    done
    cat <<EOF

The Claude Code handoff bundle carries structured metadata the ZIP does not:
brand tokens, component structure, implementation notes, and interaction
notes. Without it, the Frontend agent integrates with sparse intent and
silently invents design decisions during copy-then-edit.

Budget ~5 minutes to paste from Claude Code's handoff bundle into
$NOTES_FILE under '$ENTRY_HEADER_PREFIX':

  ### Tokens        — brand-token table (name, value, used-in)
  ### Components    — component-structure summary (variants, composition, notes)
  ### Notes         — implementation notes (free-form bullets — subtle behaviors)
  ### Interactions  — interaction notes (keyboard, gestures, timings, focus rules)

Each section must be ≥ $MIN_LINES real lines. Placeholder text from the
default template and blank lines do not count. Re-run this check after
pasting.
EOF
  } >&2
  exit 1
fi

echo "PASS: all 4 subsections of '$ENTRY_LABEL' meet the ≥ $MIN_LINES-line threshold"
exit 0
