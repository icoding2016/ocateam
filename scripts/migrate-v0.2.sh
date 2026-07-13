#!/usr/bin/env bash
# OCATeam v0.2.0 Migration Script
# Migrates from v0.1.x directory structure to v0.2.x
#
# Usage:
#   ./scripts/migrate-v0.2.sh
#
# Changes:
#   boards/          → .boards/
#   .opencode/agents/ → .opencode/.agents/
#   .opencode/skills/ → .opencode/.skills/
#   ocat.json         → .ocat.json
#   .gitignore update  boards/ → .boards/

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[migrate]${NC} $*"; }
warn() { echo -e "${YELLOW}[migrate]${NC} $*"; }
err()  { echo -e "${RED}[migrate]${NC} $*"; }

# Detect project root (run from anywhere in the project tree)
find_project_root() {
  local dir="${1:-$(pwd)}"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/ocat.json" ] || [ -f "$dir/.ocat.json" ]; then
      echo "$dir"
      return 0
    fi
    if [ -d "$dir/.opencode" ]; then
      echo "$dir"
      return 0
    fi
    if [ -d "$dir/boards" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

PROJECT_DIR="$(find_project_root)"
if [ -z "$PROJECT_DIR" ] || [ "$PROJECT_DIR" = "/" ]; then
  err "No OCATeam installation found in current directory or ancestors."
  err "Run this script from within an OCATeam project (look for ocat.json or boards/ directory)."
  exit 1
fi

log "Found project root: $PROJECT_DIR"

# ── Migrate boards/ → .boards/ ─────────────────────────
migrate_boards() {
  local old_dir="$PROJECT_DIR/boards"
  local new_dir="$PROJECT_DIR/.boards"

  if [ ! -d "$old_dir" ]; then
    log "boards/ not found — skipping boards migration"
    return 0
  fi

  if [ ! -d "$new_dir" ]; then
    mv "$old_dir" "$new_dir"
    log "Renamed boards/ → .boards/"
  elif [ -d "$new_dir" ]; then
    warn "Both boards/ and .boards/ exist — please merge manually"
    warn "  Old:  $old_dir"
    warn "  New:  $new_dir"
  fi
}

# ── Migrate .opencode/agents/ → .opencode/.agents/ ─────
migrate_agents() {
  local old_dir="$PROJECT_DIR/.opencode/agents"
  local new_dir="$PROJECT_DIR/.opencode/.agents"

  if [ ! -d "$old_dir" ]; then
    log ".opencode/agents/ not found — skipping agents migration"
    return 0
  fi

  if [ ! -d "$new_dir" ]; then
    mv "$old_dir" "$new_dir"
    log "Renamed .opencode/agents/ → .opencode/.agents/"
  elif [ -d "$new_dir" ]; then
    warn "Both .opencode/agents/ and .opencode/.agents/ exist — please merge manually"
    warn "  Old:  $old_dir"
    warn "  New:  $new_dir"
  fi
}

# ── Migrate .opencode/skills/ → .opencode/.skills/ ─────
migrate_skills() {
  local old_dir="$PROJECT_DIR/.opencode/skills"
  local new_dir="$PROJECT_DIR/.opencode/.skills"

  if [ ! -d "$old_dir" ]; then
    log ".opencode/skills/ not found — skipping skills migration"
    return 0
  fi

  if [ ! -d "$new_dir" ]; then
    mv "$old_dir" "$new_dir"
    log "Renamed .opencode/skills/ → .opencode/.skills/"
  elif [ -d "$new_dir" ]; then
    warn "Both .opencode/skills/ and .opencode/.skills/ exist — please merge manually"
    warn "  Old:  $old_dir"
    warn "  New:  $new_dir"
  fi
}

# ── Migrate ocat.json → .ocat.json ─────────────────────
migrate_ocat_json() {
  local old_file="$PROJECT_DIR/ocat.json"
  local new_file="$PROJECT_DIR/.ocat.json"

  if [ ! -f "$old_file" ]; then
    log "ocat.json not found — skipping config migration"
    return 0
  fi

  if [ ! -f "$new_file" ]; then
    mv "$old_file" "$new_file"
    log "Renamed ocat.json → .ocat.json"
  elif [ -f "$new_file" ] && [ -f "$old_file" ]; then
    warn "Both ocat.json and .ocat.json exist — keeping .ocat.json; archived old as ocat.json.v0.1.bak"
    mv "$old_file" "${old_file}.v0.1.bak"
  fi
}

# ── Update .gitignore: boards/ → .boards/ ──────────────
update_gitignore() {
  local gitignore="$PROJECT_DIR/.gitignore"

  if [ ! -f "$gitignore" ]; then
    log ".gitignore not found — skipping"
    return 0
  fi

  if grep -q "^boards/$" "$gitignore" 2>/dev/null; then
    # Use sed for in-place replacement (portable: Linux and macOS)
    if sed --version 2>/dev/null | grep -q GNU; then
      sed -i 's|^boards/$|.boards/|' "$gitignore"
    else
      sed -i '' 's|^boards/$|.boards/|' "$gitignore"
    fi
    log "Updated .gitignore: boards/ → .boards/"
  else
    log ".gitignore already has .boards/ or no boards/ entry — skipping"
  fi
}

# ── Main ───────────────────────────────────────────────
main() {
  echo ""
  log "OCATeam v0.2.0 Migration"
  log "========================"
  echo ""

  migrate_boards
  migrate_agents
  migrate_skills
  migrate_ocat_json
  update_gitignore

  echo ""
  log "Migration complete!"
  echo ""
  echo "  Next steps:"
  echo "    1. Verify your project: git status"
  echo "    2. Run: ./install.sh --project .  (to reinstall with new paths)"
  echo "    3. Start your orchestrator: opencode ."
  echo ""
}

main
