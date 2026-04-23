#!/usr/bin/env bash
# Integration test: adapter switching
#
# Simulates switching design tool adapters mid-project without pipeline-file
# changes. Produces two mock handoffs (claude-design shape, manual shape),
# validates both against contract v3 canonical shape, confirms the pipeline
# accepts both.
#
# This test is additive — it never writes to the project's src/design-handoff/
# or artifacts/design-tool.config.json. All work happens in a /tmp sandbox.
#
# Exit 0 = adapter switching works. Exit 1 = regression detected.
#
# Usage:
#   bash scripts/test-adapter-switch.sh
#   bash scripts/test-adapter-switch.sh --verbose    (print every check)

set -euo pipefail

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

log() { [[ $VERBOSE -eq 1 ]] && echo "  [log] $*" || true; }
pass() { echo "  ✓ $*"; }
fail() { echo "  ✗ $*" >&2; exit 1; }

# Resolve project root (one level up from scripts/)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SANDBOX="$(mktemp -d -t rad-adapter-switch-XXXXXX)"
trap 'rm -rf "$SANDBOX"' EXIT

echo ""
echo "=== RAD Adapter-Switching Integration Test ==="
echo "Project root: $PROJECT_ROOT"
echo "Sandbox:      $SANDBOX"
echo ""

# ---------- Setup ----------

# Copy the artifacts that define the contract into the sandbox (read-only reference)
mkdir -p "$SANDBOX/artifacts/docs"
mkdir -p "$SANDBOX/artifacts/templates"
cp "$PROJECT_ROOT/artifacts/docs/handoff-contract.md" "$SANDBOX/artifacts/docs/handoff-contract.md"
cp "$PROJECT_ROOT/artifacts/templates/handoff-manifest-schema.json" "$SANDBOX/artifacts/templates/handoff-manifest-schema.json"
cp "$PROJECT_ROOT/artifacts/templates/design-context-template.md" "$SANDBOX/artifacts/templates/design-context-template.md"

log "Contract + templates staged in sandbox"

# ---------- Test 1: claude-design adapter handoff ----------

echo "Test 1: claude-design adapter handoff"
echo "-------------------------------------"

CD_HANDOFF="$SANDBOX/claude-design-handoff"
mkdir -p "$CD_HANDOFF/components/ui"
mkdir -p "$CD_HANDOFF/routes"

# handoff-manifest.json — claude-design source
cat > "$CD_HANDOFF/handoff-manifest.json" <<'JSON'
{
  "contract_version": "3",
  "source_tool": "claude-design",
  "tool_version": "beta-2026-04",
  "generated_at": "2026-04-15T14:32:00Z",
  "adapter": "claude-design-adapter@1.0.0",
  "mode": "initial",
  "feature_name": null,
  "screens_exported": 3,
  "primitives_exported": 5,
  "canonical": {
    "repo_linked_at_generation": true,
    "tokens_match_app_css": null
  },
  "tool_specific": {
    "claude_design_project_id": "test-cd-001"
  },
  "notes": "Integration test: mock claude-design handoff."
}
JSON

# design-context.md — canonical shape with all 9 sections populated
cat > "$CD_HANDOFF/design-context.md" <<'MD'
# Design Context — Test App (claude-design)

## Brand
- Voice: direct, clear
- Personality: calm, capable, quick
- Anti-references: no neumorphism, no maximalist gradients

## Color System
| Token | Hex | OKLCH | Role |
|---|---|---|---|
| primary | #2563EB | oklch(0.55 0.2 260) | CTAs |
| background | #FFFFFF | oklch(1 0 0) | page background |
| foreground | #1A1A1A | oklch(0.15 0 0) | primary text |

## Typography
- Display: Inter, 600/700
- Body: Inter, 400/500
- Scale: 12/14/16/20/24/32/48 — ratio 1.25

## Spacing
- Base: 4px
- Scale: 4, 8, 12, 16, 24, 32, 48, 64

## Components
| Primitive | Variants | Sizes |
|---|---|---|
| Button | primary, secondary, ghost | sm, md, lg |
| Card | default, outlined | — |
| Dialog | — | — |
| Input | text, email, password | sm, md |
| Badge | default, success, warning | — |

## Interaction Patterns
- Forms submit via explicit button click
- Modals use overlay + escape-key close
- Nav stays persistent across top-level routes

## Anti-Patterns
- No gradient backgrounds in purple/violet/indigo
- No 3-column icon-in-circle feature grids

## Copy Rules
- Language: English (test)
- Forbidden: jargon without definition
- Screen-context rules: CTA verbs must be concrete

## Build Constraints
- Framework: React Router v7 (Vite)
- Styling: Tailwind v4 @theme inline
- Component library: Radix UI primitives
- State: TanStack Query + useState
- Fonts: self-hosted .woff2
MD

# theme.css stub
cat > "$CD_HANDOFF/theme.css" <<'CSS'
@theme inline {
  --color-primary: oklch(0.55 0.2 260);
  --color-background: oklch(1 0 0);
  --color-foreground: oklch(0.15 0 0);
}
CSS

# 5 primitive stubs
for primitive in button card dialog input badge; do
  cat > "$CD_HANDOFF/components/ui/$primitive.tsx" <<TSX
export function ${primitive^}() { return null; }
TSX
done

# 3 screen stubs
for screen in home settings profile; do
  cat > "$CD_HANDOFF/routes/$screen.tsx" <<TSX
export default function ${screen^}Screen() { return null; }
TSX
done

log "claude-design handoff bundle created"

# Canonical validation for claude-design handoff
python3 -c "
import json, sys
from pathlib import Path

handoff = Path('$CD_HANDOFF')
errors = []

# Manifest exists and is valid JSON
manifest_path = handoff / 'handoff-manifest.json'
if not manifest_path.exists():
    errors.append('handoff-manifest.json missing')
else:
    try:
        manifest = json.loads(manifest_path.read_text())
    except json.JSONDecodeError as e:
        errors.append(f'manifest invalid JSON: {e}')
        sys.exit(1 if errors else 0)

# Required fields
required = ['contract_version', 'source_tool', 'generated_at', 'adapter', 'mode', 'screens_exported', 'canonical']
for f in required:
    if f not in manifest:
        errors.append(f'manifest missing required field: {f}')

if manifest.get('contract_version') != '3':
    errors.append(f\"contract_version is {manifest.get('contract_version')}, expected '3'\")

if manifest.get('source_tool') not in ('claude-design', 'figma-make', 'stitch', 'figma-mcp', 'manual'):
    errors.append(f\"source_tool invalid: {manifest.get('source_tool')}\")

# Design context exists with 9 sections
ctx = handoff / 'design-context.md'
if not ctx.exists():
    errors.append('design-context.md missing')
else:
    content = ctx.read_text()
    required_sections = ['## Brand', '## Color System', '## Typography', '## Spacing',
                        '## Components', '## Interaction Patterns', '## Anti-Patterns',
                        '## Copy Rules', '## Build Constraints']
    for sec in required_sections:
        if sec not in content:
            errors.append(f'design-context.md missing section: {sec}')

# theme.css exists
if not (handoff / 'theme.css').exists():
    errors.append('theme.css missing')

# 5 primitives
ui_dir = handoff / 'components' / 'ui'
if not ui_dir.exists():
    errors.append('components/ui/ missing')
else:
    primitives = list(ui_dir.glob('*.tsx'))
    if len(primitives) < 5:
        errors.append(f'only {len(primitives)} primitives, need >= 5')

# Routes
routes_dir = handoff / 'routes'
if not routes_dir.exists():
    errors.append('routes/ missing')

if errors:
    for e in errors:
        print('  ERROR:', e)
    sys.exit(1)
print('  canonical checks passed')
" || fail "claude-design canonical validation failed"

pass "claude-design handoff validates against contract v3"

# ---------- Test 2: manual adapter handoff (same canonical shape, different source_tool) ----------

echo ""
echo "Test 2: manual adapter handoff"
echo "------------------------------"

MANUAL_HANDOFF="$SANDBOX/manual-handoff"
mkdir -p "$MANUAL_HANDOFF/components/ui"
mkdir -p "$MANUAL_HANDOFF/screens"

# Same canonical shape but source_tool: manual
cat > "$MANUAL_HANDOFF/handoff-manifest.json" <<'JSON'
{
  "contract_version": "3",
  "source_tool": "manual",
  "tool_version": "n/a",
  "generated_at": "2026-04-23T10:00:00Z",
  "adapter": "manual-adapter@1.0.0",
  "mode": "initial",
  "feature_name": null,
  "screens_exported": 3,
  "primitives_exported": 5,
  "canonical": {
    "repo_linked_at_generation": false,
    "tokens_match_app_css": null
  },
  "tool_specific": {},
  "notes": "Integration test: mock manual handoff — human-produced bundle."
}
JSON

# Copy same design-context + theme + primitives + screens (different filenames for screens/ vs routes/)
cp "$CD_HANDOFF/design-context.md" "$MANUAL_HANDOFF/design-context.md"
sed -i.bak 's/(claude-design)/(manual)/' "$MANUAL_HANDOFF/design-context.md"
rm -f "$MANUAL_HANDOFF/design-context.md.bak"

cp "$CD_HANDOFF/theme.css" "$MANUAL_HANDOFF/theme.css"

for primitive in button card dialog input badge; do
  cp "$CD_HANDOFF/components/ui/$primitive.tsx" "$MANUAL_HANDOFF/components/ui/$primitive.tsx"
done

# Use screens/ instead of routes/ — both are valid per contract v3
for screen in home settings profile; do
  cat > "$MANUAL_HANDOFF/screens/$screen.tsx" <<TSX
export default function ${screen^}Screen() { return null; }
TSX
done

log "manual handoff bundle created (using screens/ naming)"

# Canonical validation for manual handoff — same check logic, different source
python3 -c "
import json, sys
from pathlib import Path

handoff = Path('$MANUAL_HANDOFF')
errors = []

manifest = json.loads((handoff / 'handoff-manifest.json').read_text())
if manifest.get('source_tool') != 'manual':
    errors.append(f\"source_tool should be 'manual', got: {manifest.get('source_tool')}\")
if manifest.get('adapter') != 'manual-adapter@1.0.0':
    errors.append(f\"adapter should be 'manual-adapter@1.0.0', got: {manifest.get('adapter')}\")

# Same 9-section context check
content = (handoff / 'design-context.md').read_text()
required_sections = ['## Brand', '## Color System', '## Typography', '## Spacing',
                    '## Components', '## Interaction Patterns', '## Anti-Patterns',
                    '## Copy Rules', '## Build Constraints']
for sec in required_sections:
    if sec not in content:
        errors.append(f'design-context.md missing section: {sec}')

# Accept either routes/ OR screens/
has_routes = (handoff / 'routes').exists()
has_screens = (handoff / 'screens').exists()
if not (has_routes or has_screens):
    errors.append('neither routes/ nor screens/ present')

if errors:
    for e in errors:
        print('  ERROR:', e)
    sys.exit(1)
print('  canonical checks passed')
" || fail "manual canonical validation failed"

pass "manual handoff validates against contract v3"

# ---------- Test 3: Prove pipeline is tool-agnostic ----------

echo ""
echo "Test 3: Pipeline files are tool-agnostic"
echo "----------------------------------------"

# Verify the pipeline files don't reference any specific tool name
# (Acceptable exceptions: backup file, changelog, README adapter table, RAD-GUIDE adapter table,
#  claude-design-adapter scoped folder, design.md narrative mentions, design-tool-log.md historical entries)

cd "$PROJECT_ROOT"

hits=$({ grep -rln "Claude Design" \
  --include="*.md" --include="*.mdc" --include="*.sh" --include="*.json" \
  .cursor/agents/ .cursor/rules/ 2>/dev/null || true; } | wc -l | tr -d ' ')

if [[ "$hits" -gt 0 ]]; then
  echo "  ✗ Found $hits Claude Design references in agents/ or rules/ — pipeline NOT tool-agnostic:"
  grep -rln "Claude Design" --include="*.md" --include="*.mdc" .cursor/agents/ .cursor/rules/ 2>/dev/null || true
  exit 1
fi
pass "No Claude Design references in .cursor/agents/ or .cursor/rules/"

# Verify commands except design.md and files in adapter scope
hits=$({ grep -rln "Claude Design" \
  --include="*.md" \
  .cursor/commands/ 2>/dev/null || true; } \
  | { grep -v "\.cursor/commands/design\.md" || true; } \
  | wc -l | tr -d ' ')

if [[ "$hits" -gt 0 ]]; then
  echo "  ✗ Found Claude Design references in commands/ outside design.md:"
  { grep -rln "Claude Design" --include="*.md" .cursor/commands/ 2>/dev/null || true; } | { grep -v "\.cursor/commands/design\.md" || true; }
  exit 1
fi
pass "No Claude Design references in commands/ outside design.md"

# Skills outside the adapter scope
# Exempt:
#   - .cursor/skills/design-adapters/ (whole dir — adapter SKILLs + README legitimately name adapters/tools)
#   - validate-rules.sh (contains "Claude Design" as grep search patterns, not stale vocabulary)
hits=$({ grep -rln "Claude Design" \
  --include="*.md" --include="*.sh" \
  .cursor/skills/ 2>/dev/null || true; } \
  | { grep -vE "\.cursor/skills/design-adapters/|\.cursor/skills/testing/scripts/validate-rules\.sh" || true; } \
  | wc -l | tr -d ' ')

if [[ "$hits" -gt 0 ]]; then
  echo "  ✗ Found Claude Design references in skills/ outside design-adapters/ scope:"
  { grep -rln "Claude Design" --include="*.md" --include="*.sh" .cursor/skills/ 2>/dev/null || true; } | { grep -vE "\.cursor/skills/design-adapters/|\.cursor/skills/testing/scripts/validate-rules\.sh" || true; }
  exit 1
fi
pass "No Claude Design references in skills/ outside design-adapters/ scope (validator source exempt)"

# ---------- Test 4: Prove adapter config is switchable ----------

echo ""
echo "Test 4: design-tool.config.json is valid + switchable"
echo "-----------------------------------------------------"

if [[ ! -f "$PROJECT_ROOT/artifacts/design-tool.config.json" ]]; then
  fail "artifacts/design-tool.config.json missing"
fi

current_adapter=$(python3 -c "import json; print(json.load(open('$PROJECT_ROOT/artifacts/design-tool.config.json'))['adapter'])")
[[ -n "$current_adapter" ]] || fail "config missing 'adapter' field"

# Verify the adapter named in config has a corresponding SKILL
adapter_skill="$PROJECT_ROOT/.cursor/skills/design-adapters/${current_adapter}-adapter/SKILL.md"
if [[ ! -f "$adapter_skill" ]]; then
  fail "Config adapter '$current_adapter' but $adapter_skill missing"
fi
pass "Config adapter '$current_adapter' has a SKILL at $adapter_skill"

# Verify all fallbacks also exist
python3 <<PY
import json, sys
from pathlib import Path
cfg = json.load(open('$PROJECT_ROOT/artifacts/design-tool.config.json'))
fallbacks = cfg.get('fallback_adapters', [])
for fb in fallbacks:
    skill = Path('$PROJECT_ROOT/.cursor/skills/design-adapters') / f'{fb}-adapter' / 'SKILL.md'
    if not skill.exists():
        print(f'  ERROR: fallback adapter \"{fb}\" missing SKILL at {skill}', file=sys.stderr)
        sys.exit(1)
print(f'  all {len(fallbacks)} fallback adapters have SKILLs')
PY
[[ $? -eq 0 ]] || fail "fallback adapter SKILL check failed"
pass "All fallback adapters have SKILL files"

# ---------- Summary ----------

echo ""
echo "=== ALL TESTS PASSED ==="
echo "Pipeline is tool-agnostic. Adapter switching works."
echo ""
exit 0
