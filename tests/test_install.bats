#!/usr/bin/env bats
# OCATeam Tier 2 Functional Tests — install.sh behavior
# Dependencies: bats-core >= 1.0
# Run with: bats tests/test_install.bats

setup() {
  # Create temporary directories for each test
  TEST_HOME="$(mktemp -d)"
  TEST_PROJECT="$(mktemp -d)"

  # Path to the real installer and source files
  INSTALL_SCRIPT="$BATS_TEST_DIRNAME/../install.sh"
  AGENTS_SRC="$BATS_TEST_DIRNAME/../agents"
  SKILL_SRC="$BATS_TEST_DIRNAME/../skills/ocat/SKILL.md"
  SNIPPET="$BATS_TEST_DIRNAME/../scaffold/opencode.json.snippet"

  # Ensure source files exist (sanity check)
  [ -f "$INSTALL_SCRIPT" ]
  [ -d "$AGENTS_SRC" ]
  [ -f "$SKILL_SRC" ]
}

teardown() {
  rm -rf "$TEST_HOME" "$TEST_PROJECT"
}

# Override HOME for "global" install tests
run_global() {
  HOME="$TEST_HOME" bash "$INSTALL_SCRIPT" "$@"
}

run_project() {
  bash "$INSTALL_SCRIPT" "$@"
}

# ── Global Install Tests ─────────────────────────────────

@test "global: installs agents and skill" {
  run run_global --global
  [ "$status" -eq 0 ]
  [ -f "$TEST_HOME/.config/opencode/agents/ocat-orchestrator.md" ]
  [ -f "$TEST_HOME/.config/opencode/agents/ocat-architect.md" ]
  [ -f "$TEST_HOME/.config/opencode/agents/ocat-developer.md" ]
  [ -f "$TEST_HOME/.config/opencode/agents/ocat-reviewer.md" ]
  [ -f "$TEST_HOME/.config/opencode/agents/ocat-explorer.md" ]
  [ -f "$TEST_HOME/.config/opencode/skills/ocat/SKILL.md" ]
}

@test "global: installs exactly 5 agent files" {
  run run_global --global
  [ "$status" -eq 0 ]
  count=$(ls "$TEST_HOME/.config/opencode/agents"/ocat-*.md 2>/dev/null | wc -l)
  [ "$count" -eq 5 ]
}

@test "global: creates target directories if absent" {
  # Ensure target dirs don't exist yet
  rm -rf "$TEST_HOME/.config"
  run run_global --global
  [ "$status" -eq 0 ]
  [ -d "$TEST_HOME/.config/opencode/agents" ]
  [ -d "$TEST_HOME/.config/opencode/skills/ocat" ]
}

@test "global: uninstall removes all ocat files" {
  run run_global --global
  [ "$status" -eq 0 ]
  run run_global --uninstall --global
  [ "$status" -eq 0 ]
  # Agent files gone
  run ls "$TEST_HOME/.config/opencode/agents"/ocat-*.md
  [ "$status" -ne 0 ]
  # Skill dir gone
  [ ! -d "$TEST_HOME/.config/opencode/skills/ocat" ]
}

@test "global: uninstall is idempotent" {
  run run_global --global
  run run_global --uninstall --global
  [ "$status" -eq 0 ]
  run run_global --uninstall --global
  [ "$status" -eq 0 ]
}

@test "global: double install is idempotent" {
  run run_global --global
  [ "$status" -eq 0 ]
  run run_global --global
  [ "$status" -eq 0 ]
  # Files should still be there
  [ -f "$TEST_HOME/.config/opencode/agents/ocat-orchestrator.md" ]
}

# ── Per-Project Install Tests ────────────────────────────

@test "project: installs agents and skill" {
  run run_project --project "$TEST_PROJECT"
  [ "$status" -eq 0 ]
  [ -f "$TEST_PROJECT/.opencode/agents/ocat-orchestrator.md" ]
  [ -f "$TEST_PROJECT/.opencode/agents/ocat-architect.md" ]
  [ -f "$TEST_PROJECT/.opencode/agents/ocat-developer.md" ]
  [ -f "$TEST_PROJECT/.opencode/agents/ocat-reviewer.md" ]
  [ -f "$TEST_PROJECT/.opencode/agents/ocat-explorer.md" ]
  [ -f "$TEST_PROJECT/.opencode/skills/ocat/SKILL.md" ]
}

@test "project: scaffolds opencode.json when absent" {
  run run_project --project "$TEST_PROJECT"
  [ "$status" -eq 0 ]
  [ -f "$TEST_PROJECT/opencode.json" ]
  # Should be valid JSON
  python3 -c "import json; json.load(open('$TEST_PROJECT/opencode.json'))"
}

@test "project: skips scaffold when opencode.json exists" {
  # Pre-create an opencode.json
  echo '{"existing": true}' > "$TEST_PROJECT/opencode.json"
  run run_project --project "$TEST_PROJECT"
  [ "$status" -eq 0 ]
  # Original content preserved
  grep -q '"existing": true' "$TEST_PROJECT/opencode.json"
}

@test "project: errors on missing project directory" {
  run run_project --project "/tmp/nonexistent-ocat-test-dir-$$"
  [ "$status" -ne 0 ]
}

@test "project: adds .boards/ to .gitignore" {
  run run_project --project "$TEST_PROJECT"
  [ "$status" -eq 0 ]
  [ -f "$TEST_PROJECT/.gitignore" ]
  grep -qxF '.boards/' "$TEST_PROJECT/.gitignore"
}

@test "project: appends .boards/ to existing .gitignore" {
  echo 'node_modules/' > "$TEST_PROJECT/.gitignore"
  run run_project --project "$TEST_PROJECT"
  [ "$status" -eq 0 ]
  grep -qxF 'node_modules/' "$TEST_PROJECT/.gitignore"
  grep -qxF '.boards/' "$TEST_PROJECT/.gitignore"
}

@test "project: does not duplicate .boards/ in .gitignore" {
  echo '.boards/' > "$TEST_PROJECT/.gitignore"
  run run_project --project "$TEST_PROJECT"
  [ "$status" -eq 0 ]
  count=$(grep -cxF '.boards/' "$TEST_PROJECT/.gitignore")
  [ "$count" -eq 1 ]
}

# ── Error Handling Tests ─────────────────────────────────

@test "error: fails when agents source missing" {
  # Temporarily hide the agents directory
  local hidden="$BATS_TEST_DIRNAME/../agents.hidden"
  mv "$AGENTS_SRC" "$hidden"
  run run_global --global
  mv "$hidden" "$AGENTS_SRC"
  [ "$status" -ne 0 ]
}

@test "error: fails when skill source missing" {
  local hidden="$BATS_TEST_DIRNAME/../skills/ocat/SKILL.md.hidden"
  mv "$SKILL_SRC" "$hidden"
  run run_global --global
  mv "$hidden" "$SKILL_SRC"
  [ "$status" -ne 0 ]
}

# ── Argument Parsing Tests ───────────────────────────────

@test "args: --help prints usage" {
  run bash "$INSTALL_SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "args: no mode prints error" {
  run bash "$INSTALL_SCRIPT"
  [ "$status" -ne 0 ]
}

@test "args: --project without path prints error" {
  run bash "$INSTALL_SCRIPT" --project
  [ "$status" -ne 0 ]
}


