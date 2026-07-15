#!/usr/bin/env bash
# OCATeam Installer — install multi-agent framework into OpenCode
# Repository: https://github.com/YOUR_ORG/ocateam
#
# Usage:
#   ./install.sh --global              # Install globally (~/.config/opencode/)
#   ./install.sh --project <path>      # Install to a specific project
#   ./install.sh --uninstall --global  # Remove global installation
#   ./install.sh --uninstall --project <path>  # Remove from project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OCATeam_DIR="$SCRIPT_DIR"

# Colour helpers
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log()  { echo -e "${GREEN}[ocat]${NC} $*"; }
warn() { echo -e "${YELLOW}[ocat]${NC} $*"; }
err()  { echo -e "${RED}[ocat]${NC} $*" >&2; }

# Validate source directories/files exist
validate_sources() {
  local agents_src="$1"
  local skills_src="$2"

  if [ ! -d "$agents_src" ]; then
    err "Agent source directory not found: $agents_src"
    exit 1
  fi
  if [ ! -f "$skills_src/SKILL.md" ]; then
    err "Skill source not found: $skills_src/SKILL.md"
    exit 1
  fi
}

install_global() {
  local agents_src="$OCATeam_DIR/agents"
  local agents_dest="$HOME/.config/opencode/agents"
  local skills_src="$OCATeam_DIR/skills/ocat"
  local skills_dest="$HOME/.config/opencode/skills/ocat"

  validate_sources "$agents_src" "$skills_src"

  mkdir -p "$agents_dest" "$skills_dest"

  log "Installing agents → $agents_dest"
  cp "$agents_src"/*.md "$agents_dest/"
  log "  $(ls "$agents_src"/*.md 2>/dev/null | wc -l) agent(s) installed"

  log "Installing skill → $skills_dest"
  cp "$skills_src/SKILL.md" "$skills_dest/"
  log "  ocat skill installed"

  echo ""
  log "Installation complete!"
  echo ""
  echo "  Next steps:"
  echo "    1. Open any project in OpenCode"
  echo "    2. Press Tab to switch to the 'ocat-orchestrator' agent"
  echo "    3. Describe your project and the orchestrator will handle the rest"
  echo ""
  echo "  To customize models, edit: ~/.config/opencode/opencode.json"
  echo "    Example override:"
  echo '    { "agent": { "ocat-developer": { "model": "openai/gpt-5" } } }'
}

install_project() {
  local project_path="${1%/}"
  local agents_src="$OCATeam_DIR/agents"
  local agents_dest="$project_path/.opencode/agents"
  local skills_src="$OCATeam_DIR/skills/ocat"
  local skills_dest="$project_path/.opencode/skills/ocat"

  if [ ! -d "$project_path" ]; then
    err "Project directory not found: $project_path"
    exit 1
  fi

  validate_sources "$agents_src" "$skills_src"

  mkdir -p "$agents_dest" "$skills_dest"

  log "Installing agents → $agents_dest"
  cp "$agents_src"/*.md "$agents_dest/"
  log "  $(ls "$agents_src"/*.md 2>/dev/null | wc -l) agent(s) installed"

  log "Installing skill → $skills_dest"
  cp "$skills_src/SKILL.md" "$skills_dest/"
  log "  ocat skill installed"

  # Scaffold opencode.json if it doesn't exist
  local snippet="$OCATeam_DIR/scaffold/opencode.json.snippet"
  local ocat_config="$OCATeam_DIR/scaffold/ocat.json.snippet"
  if [ -f "$snippet" ] && [ ! -f "$project_path/opencode.json" ]; then
    cp "$snippet" "$project_path/opencode.json"
    log "Scaffolded opencode.json"
  elif [ -f "$snippet" ] && [ -f "$project_path/opencode.json" ]; then
    warn "opencode.json already exists — skipped scaffold"
  fi
  # Scaffold .ocat.json (always warn if exists, never overwrite)
  if [ -f "$ocat_config" ] && [ ! -f "$project_path/.ocat.json" ]; then
    cp "$ocat_config" "$project_path/.ocat.json"
    log "Scaffolded .ocat.json with v0.3.0 config"
  elif [ -f "$ocat_config" ] && [ -f "$project_path/.ocat.json" ]; then
    warn ".ocat.json already exists — skipped scaffold"
  fi

  # Ensure .boards/ is gitignored (runtime state, never committed)
  local gitignore="$project_path/.gitignore"
  if [ -f "$gitignore" ]; then
    if ! grep -qxF '.boards/' "$gitignore" 2>/dev/null; then
      echo '.boards/' >> "$gitignore"
      log "Added .boards/ to .gitignore"
    fi
  else
    echo '.boards/' > "$gitignore"
    log "Created .gitignore with .boards/"
  fi

  echo ""
  log "Installation complete!"
  echo ""
  echo "  Project: $project_path"
  echo "  Agents:  $agents_dest/"
  echo "  Skill:   $skills_dest/"
  echo ""
  echo "  To customize: edit $project_path/.opencode/agents/*.md"
}

uninstall_global() {
  local agents_dest="$HOME/.config/opencode/agents"
  local skills_dest="$HOME/.config/opencode/skills/ocat"

  log "Removing ocat agents from $agents_dest"
  rm -f "$agents_dest"/ocat-*.md
  log "Removing ocat skill from $skills_dest"
  rm -rf "$skills_dest"
  log "Uninstall complete."
}

uninstall_project() {
  local project_path="${1%/}"
  local agents_dest="$project_path/.opencode/agents"
  local skills_dest="$project_path/.opencode/skills/ocat"

  log "Removing ocat agents from $agents_dest"
  rm -f "$agents_dest"/ocat-*.md
  log "Removing ocat skill from $skills_dest"
  rm -rf "$skills_dest"
  log "Uninstall complete."
}

ocat_version() {
  local version_file="$OCATeam_DIR/VERSION"
  if [ -f "$version_file" ]; then
    cat "$version_file"
  else
    echo "unknown"
  fi
}

print_usage() {
  echo "OCATeam v$(ocat_version)"
  echo ""
  echo "Usage: $0 [--global | --project <path>] [--uninstall]"
  echo ""
  echo "Commands:"
  echo "  --global              Install OCATeam globally (~/.config/opencode/)"
  echo "  --project <path>      Install OCATeam into a specific project"
  echo "  --uninstall           Remove a previous installation (use with --global or --project)"
  echo "  -v, --version         Print OCATeam version"
  echo ""
  echo "Examples:"
  echo "  $0 --global                           # Install for all projects"
  echo "  $0 --project ~/code/my-app            # Install for one project"
  echo "  $0 --uninstall --global               # Remove global installation"
  echo "  $0 --uninstall --project ~/code/my-app # Remove from project"
}

# Parse arguments
UNINSTALL=false
MODE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global)
      MODE="global"
      shift
      ;;
    --project)
      if [[ -z "${2:-}" ]]; then
        err "--project requires a path argument"
        err "  Usage: ./install.sh --project <path>"
        exit 1
      fi
      MODE="project"
      PROJECT_PATH="$2"
      shift 2
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    -v|--version)
      echo "OCATeam v$(ocat_version)"
      exit 0
      ;;
    *)
      err "Unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
done

if [ -z "$MODE" ]; then
  err "Either --global or --project is required."
  print_usage
  exit 1
fi

if [ "$MODE" = "project" ] && [ -z "${PROJECT_PATH:-}" ]; then
  err "--project requires a path argument."
  exit 1
fi

if $UNINSTALL; then
  case "$MODE" in
    global) uninstall_global ;;
    project) uninstall_project "$PROJECT_PATH" ;;
  esac
else
  case "$MODE" in
    global) install_global ;;
    project) install_project "$PROJECT_PATH" ;;
  esac
fi
