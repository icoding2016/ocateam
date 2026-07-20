# Execution Log Format

## Location
`.boards/execution.log` — NDJSON format (one JSON object per line)

## Schema
Each log entry is a JSON object with the following fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ts` | string (ISO 8601) | Yes | Timestamp |
| `phase` | number (0-3) | Yes | Current workflow phase |
| `action` | string | Yes | Action type (see below) |
| `agent` | string | Yes | Agent name (e.g., "ocat-orchestrator") |
| `msg` | string | Yes | Human-readable message |
| `details` | object | No | Additional structured data |

## Action Types

### Orchestrator Actions
- `session_start` — New session started
- `phase_start` — Phase begins
- `phase_complete` — Phase completes
- `delegate_task` — Task delegated to subagent
- `review_start` — Review cycle starts
- `review_complete` — Review completes (APPROVED/NEEDS_REVISION)
- `escalate` — Escalation to user
- `user_confirm` — User confirmation received
- `session_end` — Session ends

### Subagent Actions
- `task_start` — Task execution starts
- `task_complete` — Task execution completes
- `board_update` — Board file updated
- `error` — Error encountered

## Example Entries

```json
{"ts":"2026-07-13T10:00:00Z","phase":0,"action":"session_start","agent":"ocat-orchestrator","msg":"New session started"}
{"ts":"2026-07-13T10:00:05Z","phase":0,"action":"phase_start","agent":"ocat-orchestrator","msg":"Phase 0: Requirements analysis"}
{"ts":"2026-07-13T10:05:00Z","phase":0,"action":"delegate_task","agent":"ocat-orchestrator","msg":"Delegated exploration to ocat-explorer","details":{"task_id":"exp-001","subagent":"ocat-explorer"}}
{"ts":"2026-07-13T10:10:00Z","phase":0,"action":"user_confirm","agent":"user","msg":"User approved implementation plan"}
{"ts":"2026-07-13T10:10:05Z","phase":1,"action":"phase_start","agent":"ocat-orchestrator","msg":"Phase 1: System design"}
```

## Usage

### Viewing Logs
```bash
# View all logs
cat .boards/execution.log

# View with jq for pretty printing
cat .boards/execution.log | jq .

# Filter by phase
cat .boards/execution.log | jq 'select(.phase == 0)'

# Filter by agent
cat .boards/execution.log | jq 'select(.agent == "ocat-orchestrator")'

# View errors
cat .boards/execution.log | jq 'select(.action == "error")'
```

### Log Rotation
For long-running projects, logs can grow large. Consider:
- Archiving old logs: `mv .boards/execution.log .boards/execution.log.1`
- Compressing: `gzip .boards/execution.log.1`
