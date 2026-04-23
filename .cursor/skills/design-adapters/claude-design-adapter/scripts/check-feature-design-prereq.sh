#!/bin/bash
# Feature → Design Prerequisite Check — M4 enforcement
#
# /new-feature Step 5 says "if the feature adds new screens, run /design
# new-feature [name]." The condition is soft. A user can skip Step 5 and
# proceed straight to /feature, after which the Frontend agent is dispatched
# without a handoff and silently invents UI.
#
# This script makes the prerequisite hard:
#   - If the feature's Frontend Scope (in artifacts/docs/features/[name].md
#     or in build-plan.md) names any screen that is NOT already in the
#     initial src/design-handoff/, then src/design-handoff/new-feature-[name]/
#     MUST exist (created by /design new-feature [name]).
#   - If both conditions hold (new screens named AND new-feature handoff
#     missing) → BLOCKING.
#
# Detection of "new screens":
#   - Read artifacts/docs/features/[name].md and grep for screen-name patterns
#     in the Frontend Scope section: any line mentioning a .tsx file or
#     ScreenName the agent should produce.
#   - Cross-reference against the file basenames in src/design-handoff/.
#   - Anything named in the feature doc but not present in the initial
#     handoff is a "new screen requiring design."
#
# Heuristic (deliberately conservative — false positives are cheap to override,
# false negatives mean the agent ships a shell):
#   - If the feature doc's Frontend Scope is empty or trivial ("backend-only")
#     → exit 0 (no design needed).
#   - If Frontend Scope mentions screens but new-feature handoff dir exists
#     → exit 0.
#   - If Frontend Scope mentions screens AND new-feature handoff dir is missing
#     → exit 1.
#
# Usage:
#   bash check-feature-design-prereq.sh <feature-name>
#
# Exit codes:
#   0 — PASS (no design needed, or handoff already in place)
#   1 — BLOCKING (new screens needed, handoff missing)
#   2 — usage / file missing

set -e

FEATURE="${1:-}"

if [ -z "$FEATURE" ]; then
  echo "usage: $0 <feature-name>" >&2
  exit 2
fi

FEATURE_DOC="artifacts/docs/features/$FEATURE.md"
HANDOFF_DIR="src/design-handoff/new-feature-$FEATURE"
INITIAL_HANDOFF="src/design-handoff"

# If the feature doc doesn't exist, we can't check — defer to the Tech Lead.
if [ ! -f "$FEATURE_DOC" ]; then
  echo "WARN: $FEATURE_DOC not found — cannot check design prerequisite. Tech Lead must manually confirm whether new screens are needed." >&2
  exit 2
fi

# Extract the Frontend Scope section. From "## Frontend Scope" (or "### Frontend Scope")
# until the next "## " heading or EOF.
SCOPE=$(awk '
  /^#{2,3} Frontend Scope/ { capture = 1; next }
  /^#{1,2} / && capture    { exit }
  capture                  { print }
' "$FEATURE_DOC")

if [ -z "$SCOPE" ]; then
  echo "WARN: no 'Frontend Scope' section found in $FEATURE_DOC — assuming no new screens; PASS by default." >&2
  exit 0
fi

# Backend-only signal — common phrasing.
if echo "$SCOPE" | grep -qiE 'backend[- ]only|no new screens|none|n/a'; then
  if ! echo "$SCOPE" | grep -qiE '\.tsx|\bscreen\b'; then
    echo "PASS: Frontend Scope is backend-only / no new screens; design prerequisite N/A"
    exit 0
  fi
fi

# Detect screen names — lines mentioning .tsx files or "Screen" pascal-case
# tokens. We're lenient: if there's any mention, treat as "new screens needed."
SCREEN_MENTIONS=$(echo "$SCOPE" | grep -oE '[A-Za-z][A-Za-z0-9_-]*\.(tsx|TSX)|\b[A-Z][a-zA-Z0-9]*Screen\b' | sort -u)

if [ -z "$SCREEN_MENTIONS" ]; then
  # No explicit screen names — might be a Scope written in prose. Look for
  # words that imply UI work.
  if echo "$SCOPE" | grep -qiE '\bscreen\b|\bpage\b|\bmodal\b|\bdialog\b|\bview\b|\broute\b|\bnav\b|\bcomponent\b'; then
    : # treat as needing design
  else
    echo "PASS: no screens or UI elements named in Frontend Scope; design prerequisite N/A"
    exit 0
  fi
fi

# Cross-check: for every named screen, is its basename already in initial handoff?
NEEDS_NEW_DESIGN=0
NEW_SCREENS=()

if [ -n "$SCREEN_MENTIONS" ]; then
  for s in $SCREEN_MENTIONS; do
    # Strip "Screen" suffix to compare on root names (e.g. NotesListScreen → notes-list)
    base=$(echo "$s" | sed -E 's/\.(tsx|TSX)$//; s/Screen$//' | tr '[:upper:]' '[:lower:]')
    # Search for this basename in the initial handoff (loose match).
    if [ -d "$INITIAL_HANDOFF" ]; then
      MATCH=$(find "$INITIAL_HANDOFF" -maxdepth 5 -type f -name "*.tsx" 2>/dev/null \
        | xargs -I{} basename {} .tsx 2>/dev/null \
        | grep -iE "(^|[-_])${base}(\$|[-_])" || true)
      if [ -z "$MATCH" ]; then
        NEEDS_NEW_DESIGN=1
        NEW_SCREENS+=("$s")
      fi
    else
      # No initial handoff to cross-check against (Foundation hasn't run?) —
      # conservatively assume new design needed.
      NEEDS_NEW_DESIGN=1
      NEW_SCREENS+=("$s")
    fi
  done
else
  # We saw UI keywords but no specific screen names. Assume design is needed.
  NEEDS_NEW_DESIGN=1
fi

if [ "$NEEDS_NEW_DESIGN" -eq 0 ]; then
  echo "PASS: every screen named in Frontend Scope already exists in $INITIAL_HANDOFF (no new design needed)"
  exit 0
fi

# At this point we believe the feature adds new screens. Check the handoff dir.
if [ -d "$HANDOFF_DIR" ] && [ -n "$(find "$HANDOFF_DIR" -maxdepth 5 -type f -name "*.tsx" 2>/dev/null | head -1)" ]; then
  echo "PASS: new-feature handoff present at $HANDOFF_DIR"
  exit 0
fi

# BLOCKING
{
  echo "BLOCKING: feature '$FEATURE' adds new screens but $HANDOFF_DIR is missing or empty."
  echo ""
  if [ ${#NEW_SCREENS[@]} -gt 0 ]; then
    echo "Screens named in Frontend Scope but not in initial handoff:"
    for s in "${NEW_SCREENS[@]}"; do
      echo "  - $s"
    done
  else
    echo "Frontend Scope mentions UI work (screen / page / modal / view) but does not name specific files."
  fi
  cat <<EOF

Run the design step first:

  /design new-feature $FEATURE
  # (human exports from Claude Design with linked repo)
  /design verify new-feature $FEATURE

Then re-run /feature $FEATURE.

If this feature genuinely does not need new screens (e.g., reuses existing
ones with minor edits), update the Frontend Scope in $FEATURE_DOC to be
explicit ("Modifies existing screens X, Y — no new screens") and re-run.
EOF
} >&2

exit 1
