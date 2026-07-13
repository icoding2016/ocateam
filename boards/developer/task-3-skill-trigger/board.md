# Task: task-3-skill-trigger — Skill Trigger Improvements

## Objective
Improve ocat skill trigger reliability: ensure the ocat skill is always loaded, add explicit session startup logic to the orchestrator, validate via tests, and document the design decision.

## Progress
- [x] Implementation
- [x] Unit tests
- [x] Integration tests
- [x] Self-review

## Changes Made
- `skills/ocat/SKILL.md`: Added `metadata.openclaw.always: true` to YAML frontmatter
- `agents/ocat-orchestrator.md`: Added "Session Startup" section with first-interaction detection logic
- `tests/validate.sh`: Added `check_skill_metadata()` function to verify `always: true` is present
- `doc/design.md`: Added design decision row "Skill always-loaded via metadata"

## Test Results
```
========================================
 OCATeam Static Validation
========================================
...
── Skill metadata ──
  ✓ Skill has openclaw.always: true
...
========================================
 Results: 27 passed, 0 failed
========================================
```

## Issues / Notes
- All 27 validation checks pass including the new `check_skill_metadata` check
- The Session Startup section guides the orchestrator through first-interaction detection, skill loading, .ocat.json reading, board initialization, and user workflow announcement
- The `openclaw.always: true` metadata ensures the skill is always eligible regardless of description-based gating rules
