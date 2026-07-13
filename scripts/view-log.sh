#!/usr/bin/env bash
# OCATeam Execution Log Viewer
# Usage: ./scripts/view-log.sh [options]
#   --phase <n>     Filter by phase (0-4)
#   --agent <name>  Filter by agent
#   --action <type> Filter by action
#   --errors        Show only errors
#   --pretty        Pretty print with jq

set -euo pipefail

LOG_FILE=".boards/execution.log"

if [ ! -f "$LOG_FILE" ]; then
  echo "No execution log found at $LOG_FILE"
  exit 1
fi

# Parse arguments
PHASE=""
AGENT=""
ACTION=""
ERRORS=false
PRETTY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phase) PHASE="$2"; shift 2 ;;
    --agent) AGENT="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --errors) ERRORS=true; shift ;;
    --pretty) PRETTY=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Build jq filter
FILTER="."
if [ -n "$PHASE" ]; then
  FILTER="$FILTER | select(.phase == $PHASE)"
fi
if [ -n "$AGENT" ]; then
  FILTER="$FILTER | select(.agent == \"$AGENT\")"
fi
if [ -n "$ACTION" ]; then
  FILTER="$FILTER | select(.action == \"$ACTION\")"
fi
if $ERRORS; then
  FILTER="$FILTER | select(.action == \"error\")"
fi

# Output
if $PRETTY; then
  cat "$LOG_FILE" | jq "$FILTER"
else
  cat "$LOG_FILE" | jq -c "$FILTER"
fi
