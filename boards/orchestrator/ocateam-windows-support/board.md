# Project: ocateam-windows-support

## Status
- Current Phase: DONE ✅
- Started: 2026-07-12
- Last Updated: 2026-07-12

## Requirements Summary
- Existing `install.sh` works on Linux and macOS — keep as-is
- Create `install.ps1` (PowerShell) for Windows support
- Must mirror all functionality of `install.sh`:
  - `--global` install to `$HOME/.config/opencode/` (use `%APPDATA%` or `$env:APPDATA` on Windows)
  - `--project <path>` install to a specific project
  - `--uninstall` for both modes
  - `--help` / `--version`
  - Same validation, logging, and error handling patterns
- Include Pester tests (`tests/test_install.ps1`) mirroring `tests/test_install.bats`
- Update `tests/validate.sh` to also check PowerShell syntax if `pwsh` is available

## Phase Progress

### Phase 0: Requirements ✅
- [x] Clarify user requirements
- [x] Analyze existing install.sh for cross-platform compatibility
- [x] Document requirements

### Phase 1: Design ✅
- [x] Design decisions documented (see below)
- [x] No architect review needed — straightforward port

### Phase 2: Implementation ✅
- [x] Create `install.ps1` (Developer) — 2026-07-12
- [x] Create `tests/test_install.ps1` Pester tests (Developer) — 2026-07-12
- [x] Update `tests/validate.sh` to check pwsh syntax (Developer) — 2026-07-12
- [x] Review (Reviewer) — iteration 1: NEEDS_REVISION, iteration 2: APPROVED

### Phase 3: Testing ✅
- [x] Run validate.sh — 24/24 passed
- [x] Fix reviewer findings (1 major + 3 minor)
- [x] Re-validate — 24/24 passed

### Phase 4: Quality Gate ✅
- [x] Final review against requirements — APPROVED

## Design Decisions

### Windows path conventions
- **Global install**: Use `$env:APPDATA\opencode\` on Windows (equivalent to `~/.config/opencode/` on Linux/macOS)
  - Rationale: `$env:APPDATA` is the standard Windows location for per-user app config
  - Alternative considered: `~/.config/opencode/` — works in PowerShell but non-standard for Windows
- **Project install**: Use `.opencode\` under the project path (same as Linux/macOS)

### PowerShell version
- Target PowerShell 5.1+ (ships with Windows 10/11) for maximum compatibility
- Also compatible with PowerShell 7+ (cross-platform)
- Use `#Requires -Version 5.1`

### Script structure
- Mirror the bash script structure: param parsing → validation → install/uninstall functions
- Use `Write-Host` with `-ForegroundColor` for colored output (equivalent to ANSI escape codes)
- Use `param()` block for argument parsing instead of manual `$1` parsing

### Testing
- Use Pester (PowerShell's testing framework) for `install.ps1` tests
- Mirror the bats test cases 1:1
- Add `pwsh -NoProfile -Command "& { ... }"` syntax check to `validate.sh` if `pwsh` is available

## Decisions Log
- 2026-07-12: Use `$env:APPDATA\opencode\` for Windows global install — standard Windows convention
- 2026-07-12: Target PowerShell 5.1+ for max compatibility
- 2026-07-12: Use Pester for PowerShell tests, mirroring bats test cases
