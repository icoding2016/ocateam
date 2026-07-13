#!/usr/bin/env bash
# OCATeam Tier 1 Static Validation
# Fast, zero-dependency-except-Python checks on all config files.
# Run with: bash tests/validate.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }

require_python() {
  if ! python3 -c "import yaml" 2>/dev/null; then
    echo "ERROR: Python3 with PyYAML required. Install: pip install pyyaml"
    exit 1
  fi
}

# ── Checks ────────────────────────────────────────────────

check_bash_syntax() {
  echo ""
  echo "── Bash syntax ──"
  if bash -n "$PROJECT_DIR/install.sh" 2>/dev/null; then
    pass "install.sh syntax valid"
  else
    fail "install.sh syntax error"
  fi
}

check_yaml_frontmatter() {
  local file="$1"
  local label="$2"
  python3 - "$file" "$label" <<'PYEOF'
import sys, yaml
path = sys.argv[1]
label = sys.argv[2]
with open(path) as f:
    content = f.read()
parts = content.split('---')
if len(parts) < 3 or not content.startswith('---'):
    print(f"✗ missing YAML frontmatter")
    sys.exit(1)
try:
    yaml.safe_load(parts[1])
except yaml.YAMLError as e:
    print(f"✗ YAML error: {e}")
    sys.exit(1)
PYEOF
}

check_all_yaml_frontmatter() {
  echo ""
  echo "── YAML frontmatter ──"
  local ok=true
  for f in "$PROJECT_DIR"/agents/ocat-*.md; do
    local name
    name=$(basename "$f")
    local output
    output=$(check_yaml_frontmatter "$f" "$name" 2>&1) || {
      fail "$name: $output"
      ok=false
      continue
    }
    pass "$name YAML valid"
  done
  local output
  output=$(check_yaml_frontmatter "$PROJECT_DIR/skills/ocat/SKILL.md" "SKILL.md" 2>&1) || {
    fail "SKILL.md: $output"
    ok=false
  }
  [ "$ok" != false ] && pass "SKILL.md YAML valid"
  $ok
}

check_json_validity() {
  echo ""
  echo "── JSON validity ──"
  local snippet="$PROJECT_DIR/scaffold/opencode.json.snippet"
  if python3 -c "import json; json.load(open('$snippet'))" 2>/dev/null; then
    pass "opencode.json.snippet valid JSON"
  else
    fail "opencode.json.snippet invalid JSON"
  fi
}

check_agent_required_fields() {
  echo ""
  echo "── Agent required fields ──"
  local ok=true
  for f in "$PROJECT_DIR"/agents/ocat-*.md; do
    local name
    name=$(basename "$f")
    local output
    output=$(python3 - "$f" "$name" <<'PYEOF'
import sys, yaml
path = sys.argv[1]
name = sys.argv[2]
with open(path) as fh:
    parts = fh.read().split('---')
cfg = yaml.safe_load(parts[1]) or {}
errors = []
for key in ['mode', 'model', 'permission']:
    if key not in cfg:
        errors.append(f"missing '{key}'")
if name in ('ocat-architect.md', 'ocat-reviewer.md'):
    if 'steps' not in cfg:
        errors.append("missing 'steps' (design requires cost cap)")
if errors:
    print(', '.join(errors))
    sys.exit(1)
PYEOF
    ) 2>&1 || {
      fail "$name: $output"
      ok=false
      continue
    }
    pass "$name required fields OK"
  done
  $ok
}

check_agent_count() {
  echo ""
  echo "── Agent count ──"
  local count
  count=$(ls "$PROJECT_DIR"/agents/ocat-*.md 2>/dev/null | wc -l)
  if [ "$count" -eq 5 ]; then
    pass "5 agent files (expected 5)"
  else
    fail "found $count agent files (expected 5)"
  fi
}

check_naming_convention() {
  echo ""
  echo "── Naming convention ──"
  local ok=true
  for f in "$PROJECT_DIR"/agents/*.md; do
    local name
    name=$(basename "$f")
    if [[ "$name" == ocat-* ]]; then
      pass "$name prefix OK"
    else
      fail "$name missing 'ocat-' prefix"
      ok=false
    fi
  done
  $ok
}

check_skill_frontmatter() {
  echo ""
  echo "── Skill frontmatter ──"
  local output
  output=$(python3 - "$PROJECT_DIR/skills/ocat/SKILL.md" <<'PYEOF'
import sys, yaml
with open(sys.argv[1]) as f:
    parts = f.read().split('---')
cfg = yaml.safe_load(parts[1]) or {}
errors = []
if cfg.get('name') != 'ocat':
    errors.append("name should be 'ocat'")
if cfg.get('compatibility') != 'opencode':
    errors.append("compatibility should be 'opencode'")
if errors:
    for e in errors: print(e)
    sys.exit(1)
PYEOF
  ) 2>&1 || {
    fail "SKILL.md frontmatter: $output"
    return
  }
  pass "SKILL.md frontmatter correct"
}

check_agent_roles_table() {
  echo ""
  echo "── Agent roles table consistency ──"
  local output
  output=$(python3 - "$PROJECT_DIR/skills/ocat/SKILL.md" "$PROJECT_DIR/agents" <<'PYEOF'
import sys, os, re

skill_path = sys.argv[1]
agents_dir = sys.argv[2]

with open(skill_path) as f:
    content = f.read()

# Extract agent names from the role summary table (| ocat-xxx | ...)
table_names = set(re.findall(r'\|\s+(ocat-\w+)\s+\|', content))

# Get actual agent filenames (strip .md)
actual_names = set(
    f.replace('.md', '')
    for f in os.listdir(agents_dir)
    if f.startswith('ocat-') and f.endswith('.md')
)

missing_in_table = actual_names - table_names
missing_in_files = table_names - actual_names

if missing_in_table:
    print(f"Agents not in SKILL.md table: {', '.join(sorted(missing_in_table))}")
if missing_in_files:
    print(f"Agents in SKILL.md table but missing files: {', '.join(sorted(missing_in_files))}")
if missing_in_table or missing_in_files:
    sys.exit(1)
PYEOF
  ) 2>&1 || {
    fail "Agent roles table: $output"
    return
  }
  pass "Agent roles table matches files (5 agents)"
}

check_snippet_keys() {
  echo ""
  echo "── Scaffold snippet keys ──"
  local output
  output=$(python3 - "$PROJECT_DIR/scaffold/ocat.json.snippet" <<'PYEOF'
import sys, json
with open(sys.argv[1]) as f:
    cfg = json.load(f)
if 'active_agents' in cfg:
    agents = cfg['active_agents']
    print(f"active_agents: {agents}")
else:
    print("missing active_agents")
    sys.exit(1)
PYEOF
  ) 2>&1 || {
    fail "ocat.json.snippet: $output"
    return
  }
  pass "ocat.json.snippet has active_agents"
}

check_no_hardcoded_paths() {
  echo ""
  echo "── No hardcoded paths ──"
  local ok=true

  # Ensure install.sh doesn't contain /home/ paths (portability)
  if grep -q '/home/' "$PROJECT_DIR/install.sh"; then
    fail "install.sh contains /home/ hardcoded paths"
    ok=false
  else
    pass "install.sh has no hardcoded /home/ paths"
  fi

  # Ensure install.ps1 doesn't contain C:\Users\ hardcoded paths
  if [ -f "$PROJECT_DIR/install.ps1" ]; then
    if grep -q 'C:\\Users\\' "$PROJECT_DIR/install.ps1"; then
      fail "install.ps1 contains C:\\Users\\ hardcoded paths"
      ok=false
    else
      pass "install.ps1 has no hardcoded C:\\Users\\ paths"
    fi
  fi

  $ok
}

check_powershell_syntax() {
  echo ""
  echo "── PowerShell syntax ──"
  if ! command -v pwsh &>/dev/null; then
    warn "pwsh not available — skipping install.ps1 syntax check"
    return
  fi

  # Use PowerShell's own parser to validate syntax (fast, no execution).
  # IMPORTANT: ParseFile returns errors in the [ref] array — it does NOT throw.
  # We MUST capture and check $errors.Count; discarding with [ref]$null
  # would silently accept broken scripts.
  if pwsh -NoProfile -Command "
    \$errors = @()
    \$null = [System.Management.Automation.Language.Parser]::ParseFile(
      '$PROJECT_DIR/install.ps1', [ref]\$null, [ref]\$errors
    )
    if (\$errors.Count -gt 0) { exit 1 } else { exit 0 }
  " 2>/dev/null; then
    pass "install.ps1 syntax valid"
  else
    fail "install.ps1 syntax error"
  fi
}

# ── Main ──────────────────────────────────────────────────

main() {
  require_python
  echo "========================================"
  echo " OCATeam Static Validation"
  echo "========================================"

  check_bash_syntax
  check_powershell_syntax
  check_all_yaml_frontmatter
  check_json_validity
  check_agent_required_fields
  check_agent_count
  check_naming_convention
  check_skill_frontmatter
  check_agent_roles_table
  check_snippet_keys
  check_no_hardcoded_paths

  echo ""
  echo "========================================"
  echo -e " Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
  echo "========================================"

  if [ "$FAIL" -gt 0 ]; then
    exit 1
  fi
}

main
