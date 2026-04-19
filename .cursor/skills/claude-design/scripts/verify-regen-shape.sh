#!/bin/bash
# Regen-Shape Verifier — H3 enforcement
#
# /design regen [screen] is meant to produce a single-file fix for one screen
# that drifted from its original Claude Design output. Trust assumption:
# Claude Design will respect "regenerate only this one screen" and not invent
# new UI primitives.
#
# In practice, prompt pressure can push Claude Design to emit new files —
# tweaked Button variants, "improved" Card primitives, helper components —
# and the previous /design verify regen check only validated mock-data shape.
# Frontend agent then copies the regen file into src/routes/_app/, the new
# imports resolve to invented primitives, and the design system silently
# forks.
#
# This script asserts:
#   1. The regen-[screen]/ directory contains exactly one .tsx file
#      (the screen file). Other files (helpers, new primitives, alternate
#      stylesheets) are forbidden.
#   2. Every `@/components/ui/*` import in the regen file resolves to a file
#      that already exists in src/components/ui/. New primitive imports =
#      invented primitives = BLOCKING.
#   3. No new theme.css, no new globals.css, no new components/ folder.
#
# Usage:
#   bash verify-regen-shape.sh <screen>
#   bash verify-regen-shape.sh <screen> custom/regen-dir
#
# Exit codes:
#   0 — PASS
#   1 — BLOCKING (one or more violations)
#   2 — usage / regen dir missing

set -e

SCREEN="${1:-}"
REGEN_DIR="${2:-}"

if [ -z "$SCREEN" ]; then
  echo "usage: $0 <screen-name> [regen-dir]" >&2
  exit 2
fi

if [ -z "$REGEN_DIR" ]; then
  REGEN_DIR="src/design-handoff/regen-$SCREEN"
fi

if [ ! -d "$REGEN_DIR" ]; then
  echo "BLOCKING: regen directory not found: $REGEN_DIR" >&2
  exit 1
fi

FAILURES=()

# ─── Check 1: directory shape — exactly one .tsx file
TSX_FILES=$(find "$REGEN_DIR" -maxdepth 5 -type f -name "*.tsx" | sort)
TSX_COUNT=$(echo "$TSX_FILES" | grep -c . || true)

if [ "$TSX_COUNT" -eq 0 ]; then
  FAILURES+=("regen directory contains no .tsx file (expected exactly one: the regenerated screen)")
elif [ "$TSX_COUNT" -gt 1 ]; then
  FAILURES+=("regen directory contains $TSX_COUNT .tsx files (expected exactly one). Extra files:")
  while IFS= read -r f; do
    FAILURES+=("    $f")
  done <<< "$(echo "$TSX_FILES" | tail -n +2)"
fi

# ─── Check 2: forbidden non-tsx files (helpers, new tokens, new primitives)
FORBIDDEN_PATTERNS=(
  "*.css"          # no new theme/globals/style files
  "*.ts"           # no new helper modules
  "*.js"
  "*.jsx"
  "*.json"         # no new package/tsconfig/manifest
)

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  HITS=$(find "$REGEN_DIR" -maxdepth 5 -type f -name "$pattern" 2>/dev/null || true)
  if [ -n "$HITS" ]; then
    FAILURES+=("forbidden file(s) matching '$pattern' in regen directory:")
    while IFS= read -r f; do
      FAILURES+=("    $f")
    done <<< "$HITS"
  fi
done

# ─── Check 3: no nested components/ or ui/ subdirs (would mean primitives invented)
for forbidden_dir in components ui hooks lib; do
  if [ -d "$REGEN_DIR/$forbidden_dir" ]; then
    FAILURES+=("forbidden subdirectory: $REGEN_DIR/$forbidden_dir (regen must be a single screen file, no shared modules)")
  fi
done

# ─── Check 4: every @/components/ui/* import resolves to an existing primitive
if [ "$TSX_COUNT" -ge 1 ]; then
  REGEN_FILE=$(echo "$TSX_FILES" | head -1)
  CANONICAL_UI_DIR="src/components/ui"

  if [ ! -d "$CANONICAL_UI_DIR" ]; then
    echo "WARN: $CANONICAL_UI_DIR not found — cannot verify primitive imports. Skipping check 4." >&2
  else
    # Extract @/components/ui/* import paths
    UI_IMPORTS=$(grep -oE 'from\s+["'"'"']@/components/ui/[a-zA-Z0-9_/-]+' "$REGEN_FILE" 2>/dev/null \
      | sed -E 's/from[[:space:]]+["'"'"']@\/components\/ui\///' \
      | sort -u)

    if [ -n "$UI_IMPORTS" ]; then
      while IFS= read -r import_path; do
        [ -z "$import_path" ] && continue
        # Try resolving as .tsx, .ts, or directory with index.tsx
        if [ -f "$CANONICAL_UI_DIR/$import_path.tsx" ] \
           || [ -f "$CANONICAL_UI_DIR/$import_path.ts" ] \
           || [ -f "$CANONICAL_UI_DIR/$import_path/index.tsx" ] \
           || [ -f "$CANONICAL_UI_DIR/$import_path/index.ts" ]; then
          continue
        fi
        FAILURES+=("invented primitive import: '@/components/ui/$import_path' — no matching file in $CANONICAL_UI_DIR/")
      done <<< "$UI_IMPORTS"
    fi
  fi
fi

# ─── Report
if [ ${#FAILURES[@]} -gt 0 ]; then
  {
    echo "BLOCKING: regen handoff for screen '$SCREEN' violates the single-file + reuse-only contract."
    echo ""
    echo "Failures:"
    for f in "${FAILURES[@]}"; do
      echo "  - $f"
    done
    cat <<EOF

A regen export must be exactly ONE .tsx file at $REGEN_DIR/<screen>.tsx that
imports only primitives already present in src/components/ui/. Any other shape
indicates Claude Design invented new files or primitives under prompt
pressure — copying them into src/ would silently fork the design system.

Fix path:
  1. In Claude Design, re-prompt with the §3 Drift Regen template from
     .cursor/skills/claude-design/SKILL.md, emphasizing:
       "Output exactly one file. Do not extract any new components.
        Only import primitives that already exist in src/components/ui/."
  2. Re-export and re-run /design verify regen $SCREEN.
  3. If Claude Design genuinely needs a new primitive, the right path is
     /design new-feature [name] (which does have an enforced budget for
     new primitives), NOT a regen.
EOF
  } >&2
  exit 1
fi

echo "PASS: regen handoff for '$SCREEN' is single-file and uses only existing primitives"
exit 0
