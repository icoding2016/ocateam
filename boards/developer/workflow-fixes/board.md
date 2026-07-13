# Task: workflow-fixes — OCAT Workflow Compliance Gaps

## Objective
Fix OCAT workflow compliance issues:
1. Strengthen orchestrator prompt to explicitly forbid direct implementation
2. Implement user confirmation step after Phase 0
3. Update design document with new design decision

## Progress
- [x] Strengthen orchestrator `Delegation` point with explicit prohibitions
- [x] Add User Confirmation Gate to SKILL.md after Phase 0
- [x] Add design decision row to doc/design.md
- [x] Run validation (`tests/validate.sh`)
- [x] Manual review of changes

## Changes Made
- `agents/ocat-orchestrator.md`: Expanded delegation point (line 27) with explicit "Do NOT attempt implementation yourself" sub-bullets covering editing code, creating files, and modifying config
- `skills/ocat/SKILL.md`: Inserted "User Confirmation Gate (After Phase 0)" section between Phase 0 and Phase 1 — includes confirmation request template and approval flow
- `doc/design.md`: Added row "User confirmation gate after Phase 0" to Key Design Decisions table

## Test Results
```
========================================
 OCATeam Static Validation
========================================
Results: 24 passed, 0 failed
========================================

All checks passed:
- Bash syntax: ✓
- YAML frontmatter (6 files): ✓
- JSON validity: ✓
- Agent required fields (5 agents): ✓
- Agent count (5): ✓
- Naming convention: ✓
- Skill frontmatter: ✓
- Agent roles table consistency: ✓
- Scaffold snippet keys: ✓
- No hardcoded paths: ✓
```

## Issues / Notes
- None
