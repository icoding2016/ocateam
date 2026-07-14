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

  # Apply permission_mode override to opencode.json
  # This uses OpenCode's agent permission merge (project > agent definition)
  local perm_mode
  if [ -f "$project_path/.ocat.json" ]; then
    perm_mode=$(jq -r '.permission_mode // "balanced"' "$project_path/.ocat.json" 2>/dev/null || echo "balanced")

    if [ "$perm_mode" != "balanced" ]; then
      local opencode_config="$project_path/opencode.json"
      # Create a temporary override that merges with existing or scaffolded opencode.json
      local override_opencode="$project_path/.opencode.tmp.json"

      if [ "$perm_mode" = "auto" ]; then
        log "Applying 'auto' permission mode — orchestrator will have bash: allow, edit: allow"
        cat > "$override_opencode" << 'PERM_EOF'
{
  "agent": {
    "ocat-orchestrator": {
      "permission": {
        "bash": "allow",
        "edit": "allow",
        "read": "allow",
        "glob": "allow",
        "grep": "allow",
        "list": "allow",
        "webfetch": "allow",
        "websearch": "allow"
      }
    }
  }
}
PERM_EOF
      elif [ "$perm_mode" = "strict" ]; then
        log "Applying 'strict' permission mode — orchestrator will have bash: ask, edit: ask"
        cat > "$override_opencode" << 'PERM_EOF'
{
  "agent": {
    "ocat-orchestrator": {
      "permission": {
        "bash": "ask",
        "edit": "ask",
        "read": "allow",
        "glob": "allow",
        "grep": "allow",
        "list": "allow",
        "webfetch": "allow",
        "websearch": "allow"
      }
    }
  }
}
PERM_EOF
      fi

      # Merge override into existing opencode.json using jq if available
      if command -v jq &>/dev/null && [ -f "$opencode_config" ]; then
        jq -s '.[0] * .[1]' "$opencode_config" "$override_opencode" > "${opencode_config}.tmp" && \
          mv "${opencode_config}.tmp" "$opencode_config"
        log "Merged permission_mode into $opencode_config"
        rm -f "$override_opencode"
      else
        warn "jq not found or opencode.json missing — saved override to $override_opencode"
        warn "  Manually merge it into $opencode_config"
      fi
    fi
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
  echo "  $0 --project ~/code/my-app --permission-mode auto  # Install + set permission mode"
  echo "  $0 --uninstall --global               # Remove global installation"
  echo "  $0 --uninstall --project ~/code/my-app # Remove from project"
  echo ""
  echo "Permission modes:"
  echo "  auto       - Full auto-approval (bash/edit: allow, no prompts)"
  echo "  balanced   - Granular bash patterns, read-only tools auto-allowed (default)"
  echo "  strict     - Require approval for bash and edit"
  echo ""
  echo "To change permission mode after install:"
  echo "  $0 --project . --permission-mode auto   # Sync config only"
  echo "  # OR manually edit .ocat.json + opencode.json"
}

# Parse arguments
UNINSTALL=false
MODE=""
PERMISSION_MODE_FLAG=""

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
    --permission-mode)
      if [[ -z "${2:-}" ]]; then
        err "--permission-mode requires a value: auto, strict, or balanced"
        exit 1
      fi
      case "$2" in
        auto|strict|balanced)
          PERMISSION_MODE_FLAG="$2"
          shift 2
          ;;
        *)
          err "Invalid --permission-mode: $2 (use: auto, strict, or balanced)"
          exit 1
          ;;
      esac
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

# If --permission-mode is given, sync it to .ocat.json first
if [ -n "$PERMISSION_MODE_FLAG" ]; then
  if [ "$MODE" != "project" ] || [ -z "${PROJECT_PATH:-}" ]; then
    err "--permission-mode requires --project <path>"
    exit 1
  fi
  ocat_json="$PROJECT_PATH/.ocat.json"
  if [ -f "$ocat_json" ]; then
    jq ".permission_mode = \"$PERMISSION_MODE_FLAG\"" "$ocat_json" > "${ocat_json}.tmp" 2>/dev/null && \
      mv "${ocat_json}.tmp" "$ocat_json" && \
      log "Updated permission_mode → $PERMISSION_MODE_FLAG in .ocat.json" || \
      warn "Failed to update .ocat.json (jq required)"
  else
    cat > "$ocat_json" << EOF
{ "permission_mode": "$PERMISSION_MODE_FLAG" }
EOF
    log "Created .ocat.json with permission_mode → $PERMISSION_MODE_FLAG"
  fi
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
