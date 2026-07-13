# Changelog

All notable changes to OCATeam will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.2.0] - 2026-07-13

### Changed
- **BREAKING**: Renamed internal directories to use dot-prefix
  - `boards/` → `.boards/`
  - `.opencode/agents/` → `.opencode/.agents/`
  - `.opencode/skills/` → `.opencode/.skills/`
  - `ocat.json` → `.ocat.json`
- Added migration script: `scripts/migrate-v0.2.sh`

## [0.1.0] — 2026-07-10

### Added
- **5 agent role definitions**: Orchestrator (primary), Architect, Developer, Reviewer, Explorer (subagents)
- **Workflow skill** (`skills/ocat/SKILL.md`): 5-phase workflow, document-based coordination, implement/refine → review cycle with MAX_REVIEW_ITERATIONS=3
- **One-command installer** (`install.sh`): global mode (`--global`) and per-project mode (`--project`) with scaffold
- **Per-project activation**: `ocat.json` controls which subagents are active
- **Board file templates**: Master board, task board, review verdict format
- **Escalation policy**: 5 triggers including review cycle exhaustion
- **Test suite**:
  - Tier 1: 23 static validation checks (`tests/validate.sh`)
  - Tier 2: 17 functional tests for `install.sh` (`tests/test_install.bats`)
  - Tier 3: POC end-to-end test — all 5 phases on `hello-cli` project (`tests/tier3_results.md`)
- **`Makefile`**: `make validate`, `make install-test`, `make test`
- **Bilingual README**: `README.md` (English) + `README.zh-CN.md` (Chinese)
- **Open-source essentials**: `VERSION`, `CHANGELOG.md`, `CONTRIBUTING.md`, `.github/` (issue templates, CI workflow)
- **Apache 2.0 License** with `NOTICE`

### Design Decisions
- All orchestration logic in agent prompts + skill; no external wrapper script
- `ocat-` prefix on agent names for global install safety
- Skill for workflow context, agents for role definitions
- Document-based coordination via `boards/` directory
- Reviewer is read-only gatekeeper (edit: deny, bash: deny)
- `steps` caps on every agent for cost bounding
- OCATeam config in `ocat.json`, OpenCode config in `opencode.json` (avoids schema conflicts)
- Two install modes: global (zero-setup) and per-project (team-committed)
