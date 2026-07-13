# Task: task-5-interaction-strategy — Implement Interaction Strategy (Plan Mode vs Smart Mode)

## Objective
Implement dual-mode interaction strategy as defined in design doc section 11.5:
- Plan Mode (Phase 0-1): Strict confirmation at every key decision
- Smart Mode (Phase 2-3): Orchestrator judges when to confirm

## Progress
- [x] Implementation
- [x] Unit tests
- [x] Integration tests (validate.sh)
- [x] Self-review

## Changes Made
- `skills/ocat/SKILL.md`: Added "Interaction Strategy" section (Plan Mode, Smart Mode, Decision Tree, Configuration, Examples)
- `agents/ocat-orchestrator.md`: Added "Interaction Strategy" reference section
- `doc/design.md`: Added "Dual-mode interaction strategy" row to Key Design Decisions table
- `tests/validate.sh`: Added `check_interaction_strategy()` function with 3 checks (documented, Plan Mode, Smart Mode)

## Test Results
```
── Interaction strategy ──
  ✓ Interaction strategy documented in SKILL.md
  ✓ Plan Mode defined
  ✓ Smart Mode defined

Results: 33 passed, 0 failed
```

## Issues / Notes
- All 33 validation checks pass
- Interaction strategy follows design doc 11.5 specification exactly
- Decision tree covers architecture changes, file count, security sensitivity, and effort estimation
- Configuration allows project-level overrides via `.ocat.json` (`interaction_mode`, `confirm_threshold`)
