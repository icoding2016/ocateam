# Task: task-1-dot-prefix — Dot-Prefixed Internal Directories

## Objective
Rename all internal directories and files to use dot-prefix to distinguish them from project code:
- Per-project install paths: `.opencode/agents/` → `.opencode/.agents/`, `.opencode/skills/` → `.opencode/.skills/`
- Project root: `ocat.json` → `.ocat.json`
- Runtime: `boards/` → `.boards/`

## Progress
- [x] Update install.sh
- [x] Update install.ps1
- [x] Update SKILL.md
- [x] Update tests (test_install.bats, test_install.ps1, validate.sh)
- [x] Create migration script
- [x] Update documentation (design.md, README.md, README.zh-CN.md)
- [x] Update .gitignore (boards/ → .boards/)
- [x] Self-review
- [x] Fix agent definition files (CRITICAL: agents/*.md had stale paths)
- [x] Fix doc/design.md remaining old paths (lines 59, 77-80, 349)
- [x] Add CHANGELOG.md v0.2.0 entry

## Changes Made

### install.sh
- Per-project dest paths: `.opencode/agents` → `.opencode/.agents`, `.opencode/skills` → `.opencode/.skills`
- Scaffolded config: `ocat.json` → `.ocat.json`
- Gitignore pattern: `boards/` → `.boards/`

### install.ps1
- Same per-project path updates as install.sh

### skills/ocat/SKILL.md
- Updated all `boards/` references → `.boards/`
- Updated all `ocat.json` references → `.ocat.json`
- Updated `.gitignore` pattern in initialization instructions

### tests/test_install.bats
- Updated all per-project path assertions to `.opencode/.agents/`, `.opencode/.skills/`, `.boards/`

### tests/test_install.ps1
- Updated all per-project path assertions (same pattern)

### tests/validate.sh
- No changes needed (source paths unchanged)

### scripts/migrate-v0.2.sh (NEW)
- Idempotent migration from v0.1.x → v0.2.x
- Handles: boards/ → .boards/, .opencode/agents/ → .opencode/.agents/, .opencode/skills/ → .opencode/.skills/, ocat.json → .ocat.json
- Updates .gitignore

### doc/design.md
- Section 4.1-4.5: Updated all `boards/` output paths → `.boards/`
- Section 3: Updated all `ocat.json` config references → `.ocat.json`
- Section 5.3: Already had `.boards/` (no change needed)
- Section 11.3: Describes the change, kept old references for context

### README.md
- Line 16: `boards/` → `.boards/`
- All `ocat.json` config references → `.ocat.json`

### README.zh-CN.md
- Line 16: `boards/` → `.boards/`
- All `ocat.json` config references → `.ocat.json`

### .gitignore
- `boards/` → `.boards/`

## Test Results
```
=== Tier 1 (validate.sh) ===
24 passed, 0 failed

=== Tier 2 (bats) ===
18 tests, 0 failures
  ok 1 global: installs agents and skill
  ok 2 global: installs exactly 5 agent files
  ok 3 global: creates target directories if absent
  ok 4 global: uninstall removes all ocat files
  ok 5 global: uninstall is idempotent
  ok 6 global: double install is idempotent
  ok 7 project: installs agents and skill
  ok 8 project: scaffolds opencode.json when absent
  ok 9 project: skips scaffold when opencode.json exists
  ok 10 project: errors on missing project directory
  ok 11 project: adds .boards/ to .gitignore
  ok 12 project: appends .boards/ to existing .gitignore
  ok 13 project: does not duplicate .boards/ in .gitignore
  ok 14 error: fails when agents source missing
  ok 15 error: fails when skill source missing
  ok 16 args: --help prints usage
  ok 17 args: no mode prints error
  ok 18 args: --project without path prints error

=== Final Check (grep for stale paths in agents/) ===
grep "boards/" (non-.boards) → 0 matches  ✓
grep "ocat.json" (non-.ocat.json) → 0 matches  ✓
```

## Changes Made (Updated: agent defs + CHANGELOG)

### agents/ocat-orchestrator.md
- Line 39: `ocat.json` → `.ocat.json`
- Line 41: `Example ocat.json:` → `Example .ocat.json:`
- Line 51: `boards/` → `.boards/`
- Line 53: `boards/orchestrator/` → `.boards/orchestrator/`

### agents/ocat-architect.md
- Line 31: `boards/architect/` → `.boards/architect/`

### agents/ocat-developer.md
- Line 26: `boards/developer/` → `.boards/developer/`

### agents/ocat-reviewer.md
- Line 37: `boards/reviewer/` → `.boards/reviewer/`

### agents/ocat-explorer.md
- Line 25: `boards/explorer/` → `.boards/explorer/`

### doc/design.md
- Line 59: `.opencode/agents/` → `.opencode/.agents/`
- Line 77: `.opencode/agents/` → `.opencode/.agents/`
- Line 78: `.opencode/skills/` → `.opencode/.skills/`
- Line 80: `ocat.json` → `.ocat.json`
- Line 349: `.opencode/agents/` → `.opencode/.agents/`

### CHANGELOG.md
- Added v0.2.0 entry documenting breaking dot-prefix changes and migration script

## Issues / Notes
- Global install paths (`~/.config/opencode/`) unchanged — already in hidden config dir
- Source directories in repo (`agents/`, `skills/`, `boards/`) unchanged (these are version-controlled sources)
- Migration script is idempotent and preserves all content
- All tests pass across Tier 1 (24 checks) and Tier 2 (18 cases)
