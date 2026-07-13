# Task: install-ps1 — Windows PowerShell Support

## Status
- **Phase**: Reviewer Feedback Applied
- **Date**: 2026-07-12 (fixed 2026-07-12)

## Files Created/Modified

### Created
1. **`install.ps1`** (262 lines) — PowerShell 5.1+ installer for Windows
   - Mirrors ALL functionality of `install.sh`
   - `-Global` install to `$env:APPDATA\opencode\`
   - `-Project <path>` install to `<project>\.opencode\`
   - `-Uninstall` support for both modes
   - `-Version` / `-Help` flags
   - `-Global` and `-Project` are mutually exclusive (improvement over bash's silent-last-wins)
   - Scaffolds `opencode.json.snippet` and `ocat.json.snippet` for project installs
   - Idempotent install and uninstall (uses `-Force`, `-ErrorAction SilentlyContinue`)
   - Uses `Write-Host -ForegroundColor` for colored output (Green/Yellow/Red)
   - `#Requires -Version 5.1` for max compatibility

2. **`tests/test_install.ps1`** (277 lines) — Pester functional tests
   - Mirrors `tests/test_install.bats` 1:1
   - 17 test cases across 4 contexts:
     - **Global Install** (6 tests): installs agents/skill, exactly 5 files, creates dirs, uninstall removes all, uninstall idempotent, double install idempotent
     - **Project Install** (4 tests): installs agents/skill, scaffolds opencode.json, skips scaffold when exists, errors on missing dir
     - **Error Handling** (2 tests): fails when agents source missing, fails when skill source missing
     - **Argument Parsing** (5 tests): -Help prints usage, no mode errors, -Project w/o path errors, -Version prints version, both -Global and -Project errors

3. **`boards/developer/install-ps1/board.md`** — this file

### Modified
4. **`tests/validate.sh`** (+36 lines) — Two additions:
   - `check_powershell_syntax()` function: runs `[System.Management.Automation.Language.Parser]::ParseFile()` via pwsh if available; skips with warning if pwsh not found
   - Extended `check_no_hardcoded_paths()` to also check `install.ps1` for `C:\Users\` paths

## Design Decisions Made

| Decision | Rationale |
|---|---|
| Subprocess invocation in Pester tests | `install.ps1` uses `exit N` (mirroring bash). Calling `exit` in-process kills Pester. Solution: invoke installer via `powershell.exe -EncodedCommand` to capture exit codes safely. |
| `-Global` + `-Project` mutual exclusion | Bash silently uses last-specified mode. PowerShell improved: both flags together = error with message. Safer UX. |
| APPDATA override in tests | `Invoke-Installer` sets `$env:APPDATA` in the subprocess command. `Invoke-InstallerProject` skips APPDATA override. Both use base64-encoded commands for safe quoting. |
| `pwsh` fallback in tests | Test helper checks for `powershell.exe` first (Windows), falls back to `pwsh` (Linux/macOS). |
| `Out-Null` for `New-Item` | Suppresses the "Directory: ..." output that `New-Item` prints by default. |

## Testing Results

- **validate.sh**: All 24 checks pass (PowerShell syntax skipped — pwsh unavailable)
- **Pester tests**: Cannot execute — pwsh not available in this Linux environment. Tests are designed for Windows execution. Syntax has been manually reviewed.

## Issues / Notes

1. **pwsh unavailable in CI/dev environment** — The Linux environment lacks PowerShell. Pester tests will need to be run on a Windows machine or a Linux host with pwsh installed. The syntax check in validate.sh gracefully skips with a warning.

2. **Pester prerequisite** — Running the tests requires Pester (typically shipped with Windows PowerShell 5.1+ or installable via `Install-Module Pester`). Not checked in validate.sh since Pester is a test dependency, not a static check dependency.

3. **Path separator handling** — PowerShell handles both `/` and `\` in paths, so the script uses `/` internally (consistent with the project structure on all platforms). Backslash is used in display strings to match Windows conventions.

## Reviewer Feedback Fixes (2026-07-12)

### Fix 1 [MAJOR]: PowerShell syntax check was a no-op
**File**: `tests/validate.sh`, `check_powershell_syntax()` function
**Problem**: `ParseFile()` returns parse errors in a `[ref]` array — it does not throw. The old code passed `[ref]$null` for the errors parameter, discarding all parse errors, so the check always reported success even for syntactically invalid PowerShell files.
**Fix**: Changed to capture errors into `$errors = @()` and check `$errors.Count -gt 0`, exiting with code 1 if any parse errors are found.

### Fix 2 [MINOR]: Missing short-form parameter aliases
**File**: `install.ps1`, param block (lines 33-41)
**Problem**: `install.sh` supports `-h` and `-v` short flags. `install.ps1` only supported `-Help` and `-Version`.
**Fix**: Added `[Alias('v')]` to `$Version` and `[Alias('h')]` to `$Help` switch parameters.

### Fix 3 [MINOR]: Missing source sanity checks in Pester BeforeAll
**File**: `tests/test_install.ps1`, BeforeAll block (lines 69-80)
**Problem**: The bats `setup()` verifies source files exist before running tests. Pester `BeforeAll` didn't.
**Fix**: Added `Should -Exist` assertions for `$InstallScript`, `$AgentsSrc`, and `$SkillSrc`.

### Fix 4 [OPTIONAL]: Join-Path usage
**Status**: Skipped — reviewer confirmed optional and not required for approval.

## Validation After Fixes
- **validate.sh**: All 24 checks pass (0 failures)
- **PowerShell syntax check**: Gracefully skipped (pwsh unavailable) — same behavior as before, but the check body is now correct for when pwsh is available.
