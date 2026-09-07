#!/usr/bin/env bats
# OCATeam Tier 2 Config Precedence Tests — model/permission override priority
#
# Verifies the empirically established merge semantics (OpenCode 1.18.x,
# confirmed via `opencode debug agent`):
#   1. A markdown agent file ALWAYS wins over inline `agent.<name>` in
#      opencode.json on conflicting fields (model AND permission).
#   2. Inline JSON only fills fields the file does not define
#      (gap-fill), or fully defines agents that have no markdown file.
#   3. Project-level files beat global-level files; project opencode.json
#      beats global opencode.json (standard config merge).
#
# Dependencies: bats-core >= 1.0, python3, `opencode` binary on PATH.
# Tests skip gracefully when `opencode` is unavailable (e.g. minimal CI).
# Run with: bats tests/test_config_precedence.bats

setup() {
  TEST_HOME="$(mktemp -d)"
  TEST_PROJECT="$(mktemp -d)"

  OPENCODE_BIN="${OPENCODE_BIN:-$(command -v opencode || true)}"
  if [ -z "$OPENCODE_BIN" ]; then
    skip "opencode binary not found on PATH"
  fi

  AGENTS_DIR="$TEST_HOME/.config/opencode/agents"
  PROJ_AGENTS_DIR="$TEST_PROJECT/.opencode/agents"
  mkdir -p "$AGENTS_DIR" "$PROJ_AGENTS_DIR"
}

teardown() {
  rm -rf "$TEST_HOME" "$TEST_PROJECT"
}

# Write a markdown agent file. $1=dir $2=model(or empty to omit) $3=edit $4=bash
mkagent() {
  local dir="$1" model="$2" edit="$3" bash_perm="$4"
  local mline=""
  [ -n "$model" ] && mline="model: $model"
  cat > "$dir/probe-agent.md" <<EOF
---
description: Probe agent
mode: subagent
$mline
permission:
  edit: $edit
  bash: $bash_perm
---
You are a probe.
EOF
}

# Write project opencode.json agent entry. Empty args omit the key.
mkjson() {
  local model="$1" edit="$2"
  local mpart="" epart=""
  [ -n "$model" ] && mpart="\"model\": \"$model\","
  [ -n "$edit" ] && epart="\"permission\": {\"edit\": \"$edit\"},"
  cat > "$TEST_PROJECT/opencode.json" <<EOF
{"\$schema": "https://opencode.ai/config.json", "agent": {"probe-agent": {$mpart$epart"mode": "subagent"}}}
EOF
}

# Print resolved model + edit/bash actions, one per line
resolved() {
  cd "$TEST_PROJECT" && HOME="$TEST_HOME" "$OPENCODE_BIN" debug agent probe-agent 2>/dev/null | python3 -c "
import json, sys
d = json.load(sys.stdin)
m = d.get('model', {})
print('model=' + m.get('providerID', '?') + '/' + m.get('modelID', '?'))
for perm in ('edit', 'bash'):
    acts = [e['action'] for e in d.get('permission', []) if e.get('permission') == perm]
    print(perm + '=' + (acts[0] if acts else 'ABSENT'))
"
}

# ── Model precedence ─────────────────────────────────────

@test "model: global file defines model (baseline)" {
  mkagent "$AGENTS_DIR" probe-provider/model-file-a deny ask
  run resolved
  [ "$status" -eq 0 ]
  [[ "$output" == *"model=probe-provider/model-file-a"* ]]
}

@test "model: project opencode.json does NOT override file model" {
  mkagent "$AGENTS_DIR" probe-provider/model-file-a deny ask
  mkjson probe-provider/model-json-b ""
  run resolved
  [ "$status" -eq 0 ]
  [[ "$output" == *"model=probe-provider/model-file-a"* ]]
}

@test "model: project file overrides global file" {
  mkagent "$AGENTS_DIR" probe-provider/model-file-a deny ask
  mkagent "$PROJ_AGENTS_DIR" probe-provider/model-proj-c deny ask
  run resolved
  [ "$status" -eq 0 ]
  [[ "$output" == *"model=probe-provider/model-proj-c"* ]]
}

@test "model: project file wins over global file AND json" {
  mkagent "$AGENTS_DIR" probe-provider/model-file-a deny ask
  mkagent "$PROJ_AGENTS_DIR" probe-provider/model-proj-c deny ask
  mkjson probe-provider/model-json-b ""
  run resolved
  [ "$status" -eq 0 ]
  [[ "$output" == *"model=probe-provider/model-proj-c"* ]]
}

@test "model: JSON-only agent (no file) resolves from JSON" {
  mkjson probe-provider/model-json-only ""
  run resolved
  [ "$status" -eq 0 ]
  [[ "$output" == *"model=probe-provider/model-json-only"* ]]
}

@test "model: JSON fills model missing from file (gap-fill)" {
  mkagent "$AGENTS_DIR" "" deny ask
  mkjson probe-provider/model-gapfill ""
  run resolved
  [ "$status" -eq 0 ]
  [[ "$output" == *"model=probe-provider/model-gapfill"* ]]
}

# ── Permission precedence ────────────────────────────────

@test "permission: JSON edit does NOT override file edit=deny" {
  mkagent "$AGENTS_DIR" probe-provider/model-file-a deny ask
  mkjson "" allow
  run resolved
  [ "$status" -eq 0 ]
  [[ "$output" == *"edit=deny"* ]]
}

@test "permission: project file edit wins over JSON" {
  mkagent "$AGENTS_DIR" probe-provider/model-file-a deny ask
  mkagent "$PROJ_AGENTS_DIR" probe-provider/model-proj-c allow ask
  mkjson "" deny
  run resolved
  [ "$status" -eq 0 ]
  [[ "$output" == *"edit=allow"* ]]
}

@test "permission: project file overrides global file" {
  mkagent "$AGENTS_DIR" probe-provider/model-file-a deny ask
  mkagent "$PROJ_AGENTS_DIR" probe-provider/model-proj-c allow ask
  run resolved
  [ "$status" -eq 0 ]
  [[ "$output" == *"edit=allow"* ]]
}
