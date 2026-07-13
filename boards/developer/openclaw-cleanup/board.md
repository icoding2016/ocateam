# OpenClaw Dependency Cleanup — Developer Task Board

## Task: Clean OpenClaw Dependency Residuals

**Task ID**: `openclaw-cleanup`
**Status**: ✅ COMPLETE
**Date**: 2026-07-13

---

## Background

During v0.2.0 Task 3 (Skill Trigger Improvements), `metadata.openclaw.always: true` was incorrectly introduced into the OCATeam codebase. OCATeam is built on **OpenCode** and should have zero OpenClaw dependencies. OpenCode skills are always eligible by default — no metadata gating is needed.

## Root Cause

Developer agent referenced OpenClaw documentation instead of OpenCode documentation during Task 3 implementation.

## Changes Made

### 1. `tests/validate.sh` — Removed `check_skill_metadata()` function

**Before** (lines 187-196):
```bash
check_skill_metadata() {
  echo ""
  echo "── Skill metadata ──"
  # Check that SKILL.md has openclaw.always: true
  if grep -q "always: true" "$PROJECT_DIR/skills/ocat/SKILL.md"; then
    pass "Skill has openclaw.always: true"
  else
    fail "Skill missing openclaw.always: true"
  fi
}
```

**After**: Function removed entirely. Also removed `check_skill_metadata` call from `main()` (was at line 389).

### 2. `doc/design.md` — Removed OpenClaw metadata references

**Line 305** (Key Design Decisions table):
- Removed: `| **Skill always-loaded via metadata** | ...`
- Rationale: This design decision was based on the false premise that skills need metadata to be eligible. In OpenCode, skills are always eligible by default.

**Line 396** (Section 11.1, Solution):
- Removed: `3. **Metadata gating**: Consider adding \`metadata.openclaw.always: true\` to ensure the skill is always eligible.`
- The remaining solutions (agent-level trigger and explicit startup message) are sufficient.

### 3. Already Cleaned (before this task)

- ✅ `skills/ocat/SKILL.md` — `metadata.openclaw.always: true` already removed from YAML frontmatter

## Verification

### Static Validation (Tier 1)
```
bash tests/validate.sh
```

**Results**: 32 passed, 0 failed ✅

All checks pass:
- Bash syntax: ✓
- YAML frontmatter (6): ✓
- JSON validity: ✓
- Agent required fields (5): ✓
- Agent count: ✓
- Naming convention (5): ✓
- Skill frontmatter: ✓
- Agent roles table: ✓
- Scaffold snippet keys: ✓
- No hardcoded paths (2): ✓
- Confirmation gate (2): ✓
- Interaction strategy (3): ✓
- Execution log documentation (3): ✓

### OpenClaw references check
```
grep -r "openclaw" --include="!(boards/**)" .
```

**Results**: 0 matches in source/config files. The only remaining references are in board files (historical record):

| File | Content | Status |
|------|---------|--------|
| `boards/orchestrator/v0.2-improvements/board.md` | Tracking the contamination issue | ✅ Historical record |
| `boards/developer/task-3-skill-trigger/board.md` | Original task implementation record | ✅ Historical record |
| `tests/validate.sh` | `check_skill_metadata` function | ✅ REMOVED |
| `doc/design.md` | Line 305 + Line 396 | ✅ REMOVED |
| `skills/ocat/SKILL.md` | YAML frontmatter | ✅ REMOVED (prior) |

## Files Modified

| File | Change | Lines |
|------|--------|-------|
| `tests/validate.sh` | Removed `check_skill_metadata()` function and its call in `main()` | -10 lines |
| `doc/design.md` | Removed "Skill always-loaded via metadata" design decision row | -1 line |
| `doc/design.md` | Removed metadata gating bullet point from Section 11.1 | -1 line |

## Conclusion

All OpenClaw dependency residuals have been cleaned from OCATeam source files. The codebase is now purely OpenCode-aligned.
