#!/bin/bash
# Handoff Token Freshness Check — C2 enforcement
#
# The single biggest quality lever in RAD's Claude Design workflow is linking
# the repo before generating. Without the link, Claude Design invents new
# brand tokens every run — the file shape of the handoff still passes /design
# verify's structural checks, but tokens drift silently.
#
# This script catches the drift by comparing token NAMES:
#   - initial:     theme.css must contain at least 3 role-keyed tokens that
#                  match EDS §5 Visual Direction expected roles (primary,
#                  background, foreground, surface, muted, accent, ...)
#   - new-feature / regen (post-Foundation):
#                  every CSS custom property in the new theme.css must already
#                  exist in src/app.css. Any unknown token = invented = link
#                  was stale or absent.
#
# Usage:
#   bash verify-handoff-tokens.sh initial src/design-handoff
#   bash verify-handoff-tokens.sh new-feature src/design-handoff/new-feature-[name]
#   bash verify-handoff-tokens.sh regen src/design-handoff/regen-[screen]
#
# Exit codes:
#   0 — PASS (token names suggest repo link was active)
#   1 — BLOCKING (token drift detected; see output for details)
#   2 — WARN (couldn't determine; see output)

set -e

MODE="${1:-}"
HANDOFF_DIR="${2:-}"

if [ -z "$MODE" ] || [ -z "$HANDOFF_DIR" ]; then
  echo "usage: $0 <initial|new-feature|regen> <handoff-dir>" >&2
  exit 2
fi

if [ ! -d "$HANDOFF_DIR" ]; then
  echo "BLOCKING: handoff directory not found: $HANDOFF_DIR" >&2
  exit 1
fi

# Locate the theme file — prefer theme.css at the root, else search.
THEME_FILE="$HANDOFF_DIR/theme.css"
if [ ! -f "$THEME_FILE" ]; then
  THEME_FILE=$(find "$HANDOFF_DIR" -maxdepth 3 -type f \
    \( -name "theme.css" -o -name "tokens.css" -o -name "colors.css" \) \
    2>/dev/null | head -1)
fi

# Incremental handoffs (new-feature / regen) may legitimately have no theme.css —
# that means Claude Design reused existing tokens, which is what we want.
if [ -z "$THEME_FILE" ] || [ ! -f "$THEME_FILE" ]; then
  if [ "$MODE" = "initial" ]; then
    echo "BLOCKING: theme.css missing in initial handoff — Claude Design must emit brand tokens"
    exit 1
  fi
  echo "PASS: no theme.css in handoff — Claude Design reused existing tokens (expected for $MODE)"
  exit 0
fi

# Extract CSS custom property names (`--foo-bar`) declared in the theme file.
HANDOFF_TOKENS=$(grep -oE '^[[:space:]]*--[a-zA-Z0-9_-]+' "$THEME_FILE" 2>/dev/null \
  | sed 's/^[[:space:]]*//' | sort -u)

if [ -z "$HANDOFF_TOKENS" ]; then
  echo "WARN: no CSS custom properties (--foo) found in $THEME_FILE"
  echo "      Claude Design may be using @theme inline without declarations this script recognizes."
  echo "      Manually verify tokens match EDS §5 or src/app.css."
  exit 2
fi

TOKEN_COUNT=$(echo "$HANDOFF_TOKENS" | wc -l | tr -d ' ')

# ─────────────────────────────────────────────────────────────────
# Mode: initial
# ─────────────────────────────────────────────────────────────────
# Foundation hasn't run yet, so src/app.css doesn't exist. Compare against
# expected role keywords instead. Claude Design, when given the EDS §5 brand
# palette via the linked repo, will produce tokens named with these roles.
if [ "$MODE" = "initial" ]; then
  ROLE_KEYWORDS="primary background foreground surface muted accent success danger warning"
  MATCHES=0
  MATCHED_ROLES=""

  for role in $ROLE_KEYWORDS; do
    if echo "$HANDOFF_TOKENS" | grep -qiE "^--(color-)?${role}(-|$)|^--${role}$"; then
      MATCHES=$((MATCHES + 1))
      MATCHED_ROLES="$MATCHED_ROLES $role"
    fi
  done

  if [ "$MATCHES" -lt 3 ]; then
    cat >&2 <<EOF
BLOCKING: theme.css token names do not match expected EDS §5 Visual Direction roles.

Found $TOKEN_COUNT tokens in $THEME_FILE (none or < 3 role-keyed):
$(echo "$HANDOFF_TOKENS" | head -20 | sed 's/^/  /')

Expected at least 3 tokens keyed by one of: primary, background, foreground,
surface, muted, accent, success, danger, warning (with or without --color- prefix).

Matched roles: ${MATCHED_ROLES:-none}

Likely cause: the repo was not linked in Claude Design before generating.
Without the link, Claude Design invents token names instead of matching the
EDS §5 brand palette. Re-link the repo in Claude Design (Import → GitHub or
Local Directory), confirm the EDS is accessible in the workspace, and
regenerate.
EOF
    exit 1
  fi

  echo "PASS: initial handoff — $MATCHES/$(echo "$ROLE_KEYWORDS" | wc -w | tr -d ' ') expected role keywords found in theme tokens ($MATCHED_ROLES)"
  exit 0
fi

# ─────────────────────────────────────────────────────────────────
# Mode: new-feature | regen (post-Foundation)
# ─────────────────────────────────────────────────────────────────
# src/app.css is the canonical token set after Foundation copies the initial
# theme.css into it. The incremental handoff must only reference tokens that
# already exist there.
CANONICAL="src/app.css"
if [ ! -f "$CANONICAL" ]; then
  cat >&2 <<EOF
WARN: $CANONICAL not found — cannot run post-Foundation token diff.

This check assumes Foundation has already copied the initial theme.css into
src/app.css. If Foundation hasn't run yet, use MODE=initial instead.
EOF
  exit 2
fi

CANONICAL_TOKENS=$(grep -oE '^[[:space:]]*--[a-zA-Z0-9_-]+' "$CANONICAL" 2>/dev/null \
  | sed 's/^[[:space:]]*//' | sort -u)

if [ -z "$CANONICAL_TOKENS" ]; then
  cat >&2 <<EOF
WARN: no CSS custom properties found in $CANONICAL. Cannot diff.
      Foundation may not have copied Claude Design's theme.css yet.
EOF
  exit 2
fi

# Tokens in handoff but not in canonical = invented by Claude Design this run.
INVENTED=$(comm -23 <(echo "$HANDOFF_TOKENS") <(echo "$CANONICAL_TOKENS"))

if [ -n "$INVENTED" ]; then
  INVENTED_COUNT=$(echo "$INVENTED" | wc -l | tr -d ' ')
  cat >&2 <<EOF
BLOCKING: $HANDOFF_DIR/theme.css invents $INVENTED_COUNT token(s) not present in $CANONICAL.

Invented tokens:
$(echo "$INVENTED" | sed 's/^/  /')

Likely cause: the repo link in Claude Design was stale or absent when this
handoff was generated. Without a current link, Claude Design cannot read
$CANONICAL and regenerates tokens from scratch — this is the exact drift
the link is supposed to prevent.

Fix:
  1. In Claude Design, re-sync the repo link (Import → re-select the repo).
  2. Confirm the workspace sidebar shows the current $CANONICAL content.
  3. Regenerate this handoff; verify no new tokens appear.

If the new tokens are intentional (new brand extension approved by Tech Lead),
add them to $CANONICAL first, then re-run this check.
EOF
  exit 1
fi

echo "PASS: all $TOKEN_COUNT handoff tokens match $CANONICAL — repo link was active"
exit 0
