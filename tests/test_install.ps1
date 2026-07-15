#Requires -Version 5.1
<#
.SYNOPSIS
  OCATeam Tier 2 Functional Tests — install.ps1 behavior
.DESCRIPTION
  Pester tests mirroring tests/test_install.bats 1:1.
  Run with: Invoke-Pester -Script tests/test_install.ps1
#>

Describe "install.ps1" {

    BeforeAll {
        # Discover the PowerShell executable (powershell.exe on Windows, pwsh on Linux)
        $PSExecutable = if (Get-Command powershell.exe -ErrorAction SilentlyContinue) {
            "powershell.exe"
        }
        else {
            "pwsh"
        }

        $ScriptDir     = Split-Path -Parent $PSCommandPath
        $InstallScript = Resolve-Path (Join-Path $ScriptDir "..\install.ps1")
        $AgentsSrc     = Resolve-Path (Join-Path $ScriptDir "..\agents")
        $SkillSrc      = Resolve-Path (Join-Path $ScriptDir "..\skills\ocat\SKILL.md")
        $Snippet       = Resolve-Path (Join-Path $ScriptDir "..\scaffold\opencode.json.snippet")

        # ── Helper: invoke install.ps1 in a child process ──────────
        # Runs the installer in a subprocess so that 'exit N' inside
        # install.ps1 does not kill the Pester test runner.
        function Invoke-Installer {
            param(
                [string]$Arguments,
                [string]$AppDataOverride
            )

            # Build a script block that sets APPDATA then runs the installer
            $innerScript = "`$env:APPDATA = '$AppDataOverride'; & '$InstallScript' $Arguments"
            $encoded = [Convert]::ToBase64String(
                [System.Text.Encoding]::Unicode.GetBytes($innerScript)
            )

            $output = & $PSExecutable -NoProfile -EncodedCommand $encoded 2>&1 | Out-String
            $exitCode = $LASTEXITCODE

            return @{
                ExitCode = $exitCode
                Output   = $output
            }
        }

        # ── Helper: invoke install.ps1 for project tests ───────────
        # Project tests don't override APPDATA, but we still run in a
        # subprocess to capture exit codes safely.
        function Invoke-InstallerProject {
            param([string]$Arguments)

            $encoded = [Convert]::ToBase64String(
                [System.Text.Encoding]::Unicode.GetBytes(
                    "& '$InstallScript' $Arguments"
                )
            )

            $output = & $PSExecutable -NoProfile -EncodedCommand $encoded 2>&1 | Out-String
            $exitCode = $LASTEXITCODE

            return @{
                ExitCode = $exitCode
                Output   = $output
            }
        }

        # Sanity checks (mirror bats setup)
        $InstallScript | Should -Exist
        $AgentsSrc | Should -Exist
        $SkillSrc | Should -Exist
    }

    BeforeEach {
        # Create temporary directories for each test
        $script:TestHome    = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        $script:TestProject = Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName())
        New-Item -ItemType Directory -Path $script:TestHome    | Out-Null
        New-Item -ItemType Directory -Path $script:TestProject | Out-Null
    }

    AfterEach {
        Remove-Item -Recurse -Force $script:TestHome    -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force $script:TestProject -ErrorAction SilentlyContinue
    }

    # ── Global Install Tests ────────────────────────────

    Context "Global Install" {

        It "installs agents and skill" {
            $result = Invoke-Installer -Arguments "-Global" -AppDataOverride $TestHome
            $result.ExitCode | Should -Be 0

            Join-Path $TestHome "opencode\agents\ocat-orchestrator.md"  | Should -Exist
            Join-Path $TestHome "opencode\agents\ocat-architect.md"     | Should -Exist
            Join-Path $TestHome "opencode\agents\ocat-developer.md"     | Should -Exist
            Join-Path $TestHome "opencode\agents\ocat-reviewer.md"      | Should -Exist
            Join-Path $TestHome "opencode\agents\ocat-explorer.md"      | Should -Exist
            Join-Path $TestHome "opencode\skills\ocat\SKILL.md"         | Should -Exist
        }

        It "installs exactly 5 agent files" {
            $result = Invoke-Installer -Arguments "-Global" -AppDataOverride $TestHome
            $result.ExitCode | Should -Be 0

            $agentsDir = Join-Path $TestHome "opencode\agents"
            $count = @(Get-ChildItem "$agentsDir\ocat-*.md").Count
            $count | Should -Be 5
        }

        It "creates target directories if absent" {
            # Ensure target directories don't exist yet
            $configDir = Join-Path $TestHome "opencode"
            if (Test-Path $configDir) { Remove-Item -Recurse -Force $configDir }

            $result = Invoke-Installer -Arguments "-Global" -AppDataOverride $TestHome
            $result.ExitCode | Should -Be 0

            Join-Path $TestHome "opencode\agents"        | Should -Exist
            Join-Path $TestHome "opencode\skills\ocat"   | Should -Exist
        }

        It "uninstall removes all ocat files" {
            # Install first
            $r1 = Invoke-Installer -Arguments "-Global" -AppDataOverride $TestHome
            $r1.ExitCode | Should -Be 0

            # Then uninstall
            $r2 = Invoke-Installer -Arguments "-Uninstall -Global" -AppDataOverride $TestHome
            $r2.ExitCode | Should -Be 0

            # Agent files should be gone
            $agentsDir = Join-Path $TestHome "opencode\agents"
            $ocatFiles = @(Get-ChildItem "$agentsDir\ocat-*.md" -ErrorAction SilentlyContinue)
            $ocatFiles.Count | Should -Be 0

            # Skill directory should be gone
            Join-Path $TestHome "opencode\skills\ocat" | Should -Not -Exist
        }

        It "uninstall is idempotent" {
            Invoke-Installer -Arguments "-Global" -AppDataOverride $TestHome
            $r1 = Invoke-Installer -Arguments "-Uninstall -Global" -AppDataOverride $TestHome
            $r1.ExitCode | Should -Be 0

            $r2 = Invoke-Installer -Arguments "-Uninstall -Global" -AppDataOverride $TestHome
            $r2.ExitCode | Should -Be 0
        }

        It "double install is idempotent" {
            $r1 = Invoke-Installer -Arguments "-Global" -AppDataOverride $TestHome
            $r1.ExitCode | Should -Be 0

            $r2 = Invoke-Installer -Arguments "-Global" -AppDataOverride $TestHome
            $r2.ExitCode | Should -Be 0

            # Files should still be there
            Join-Path $TestHome "opencode\agents\ocat-orchestrator.md" | Should -Exist
        }
    }

    # ── Per-Project Install Tests ───────────────────────

    Context "Project Install" {

        It "installs agents and skill" {
            $result = Invoke-InstallerProject -Arguments "-Project `"$TestProject`""
            $result.ExitCode | Should -Be 0

            Join-Path $TestProject ".opencode\agents\ocat-orchestrator.md" | Should -Exist
            Join-Path $TestProject ".opencode\agents\ocat-architect.md"    | Should -Exist
            Join-Path $TestProject ".opencode\agents\ocat-developer.md"    | Should -Exist
            Join-Path $TestProject ".opencode\agents\ocat-reviewer.md"     | Should -Exist
            Join-Path $TestProject ".opencode\agents\ocat-explorer.md"     | Should -Exist
            Join-Path $TestProject ".opencode\skills\ocat\SKILL.md"        | Should -Exist
        }

        It "scaffolds opencode.json when absent" {
            $result = Invoke-InstallerProject -Arguments "-Project `"$TestProject`""
            $result.ExitCode | Should -Be 0

            $ocJsonPath = Join-Path $TestProject "opencode.json"
            $ocJsonPath | Should -Exist

            # Should be valid JSON
            $content = Get-Content $ocJsonPath -Raw | ConvertFrom-Json
            $content | Should -Not -BeNullOrEmpty
        }

        It "skips scaffold when opencode.json exists" {
            # Pre-create an opencode.json
            $ocJsonPath = Join-Path $TestProject "opencode.json"
            '{"existing": true}' | Set-Content $ocJsonPath

            $result = Invoke-InstallerProject -Arguments "-Project `"$TestProject`""
            $result.ExitCode | Should -Be 0

            # Original content preserved
            $content = Get-Content $ocJsonPath -Raw
            $content | Should -Match '"existing":\s*true'
        }

        It "errors on missing project directory" {
            $nonexistent = Join-Path ([System.IO.Path]::GetTempPath()) "nonexistent-ocat-test-$(Get-Random)"
            $result = Invoke-InstallerProject -Arguments "-Project `"$nonexistent`""
            $result.ExitCode | Should -Not -Be 0
        }

        It "adds .boards/ to .gitignore" {
            $result = Invoke-InstallerProject -Arguments "-Project `"$TestProject`""
            $result.ExitCode | Should -Be 0

            $gitignorePath = Join-Path $TestProject ".gitignore"
            $gitignorePath | Should -Exist
            $content = Get-Content $gitignorePath -Raw
            $content | Should -Match '(?m)^\.boards/$'
        }

        It "appends .boards/ to existing .gitignore" {
            $gitignorePath = Join-Path $TestProject ".gitignore"
            "node_modules/" | Set-Content $gitignorePath

            $result = Invoke-InstallerProject -Arguments "-Project `"$TestProject`""
            $result.ExitCode | Should -Be 0

            $content = Get-Content $gitignorePath -Raw
            $content | Should -Match 'node_modules/'
            $content | Should -Match '(?m)^\.boards/$'
        }

        It "does not duplicate .boards/ in .gitignore" {
            $gitignorePath = Join-Path $TestProject ".gitignore"
            ".boards/" | Set-Content $gitignorePath

            $result = Invoke-InstallerProject -Arguments "-Project `"$TestProject`""
            $result.ExitCode | Should -Be 0

            $content = Get-Content $gitignorePath
            $matches = $content | Where-Object { $_ -eq '.boards/' }
            $matches.Count | Should -Be 1
        }
    }

    # ── Error Handling Tests ────────────────────────────

    Context "Error Handling" {

        It "fails when agents source missing" {
            # Temporarily hide the agents directory
            $hidden = "$AgentsSrc.hidden"
            Rename-Item $AgentsSrc $hidden

            try {
                $result = Invoke-Installer -Arguments "-Global" -AppDataOverride $TestHome
                $result.ExitCode | Should -Not -Be 0
            }
            finally {
                Rename-Item $hidden $AgentsSrc -ErrorAction SilentlyContinue
            }
        }

        It "fails when skill source missing" {
            $hidden = "$SkillSrc.hidden"
            Rename-Item $SkillSrc $hidden

            try {
                $result = Invoke-Installer -Arguments "-Global" -AppDataOverride $TestHome
                $result.ExitCode | Should -Not -Be 0
            }
            finally {
                Rename-Item $hidden $SkillSrc -ErrorAction SilentlyContinue
            }
        }
    }

    # ── Argument Parsing Tests ──────────────────────────

    Context "Argument Parsing" {

        It "-Help prints usage" {
            $result = Invoke-InstallerProject -Arguments "-Help"
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match "Usage:"
        }

        It "no mode prints error" {
            $result = Invoke-InstallerProject -Arguments ""
            $result.ExitCode | Should -Not -Be 0
        }

        It "-Project without path prints error" {
            $result = Invoke-InstallerProject -Arguments "-Project"
            $result.ExitCode | Should -Not -Be 0
        }

        It "-Version prints version" {
            $result = Invoke-InstallerProject -Arguments "-Version"
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match "OCATeam"
        }

        It "errors when both -Global and -Project are specified" {
            $result = Invoke-Installer -Arguments "-Global -Project `"$TestProject`"" -AppDataOverride $TestHome
            $result.ExitCode | Should -Not -Be 0
        }
    }
}
