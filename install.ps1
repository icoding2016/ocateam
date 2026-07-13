#Requires -Version 5.1
<#
.SYNOPSIS
  OCATeam Installer — install multi-agent framework into OpenCode
  Repository: https://github.com/YOUR_ORG/ocateam

.DESCRIPTION
  Installs OCATeam agents and the ocat skill into OpenCode, either
  globally (for all projects) or into a specific project.

.PARAMETER Global
  Install globally to $env:APPDATA\opencode\

.PARAMETER Project
  Install into a specific project at <path>\.opencode\

.PARAMETER Uninstall
  Remove a previous installation (use with -Global or -Project)

.PARAMETER Version
  Print OCATeam version from VERSION file

.PARAMETER Help
  Display this help message

.EXAMPLE
  .\install.ps1 -Global
  .\install.ps1 -Project C:\code\my-app
  .\install.ps1 -Uninstall -Global
  .\install.ps1 -Uninstall -Project C:\code\my-app
#>

param(
    [switch]$Global,
    [string]$Project,
    [switch]$Uninstall,
    [Alias('v')]
    [switch]$Version,
    [Alias('h')]
    [switch]$Help
)

$ErrorActionPreference = "Continue"

# ── Paths ──────────────────────────────────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OCATeamDir = $ScriptDir

# ── Colour helpers (Write-Host) ────────────────────────────
function Write-Log  { Write-Host "[ocat] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[ocat] $args" -ForegroundColor Yellow }
function Write-Err  { Write-Host "[ocat] $args" -ForegroundColor Red }

# ── Validate source directories/files exist ────────────────
function Validate-Sources {
    param([string]$AgentsSrc, [string]$SkillsSrc)

    if (-not (Test-Path $AgentsSrc -PathType Container)) {
        Write-Err "Agent source directory not found: $AgentsSrc"
        exit 1
    }
    if (-not (Test-Path "$SkillsSrc/SKILL.md" -PathType Leaf)) {
        Write-Err "Skill source not found: $SkillsSrc/SKILL.md"
        exit 1
    }
}

# ── Install globally ───────────────────────────────────────
function Install-Global {
    $agentsSrc  = "$OCATeamDir/agents"
    $agentsDest = "$env:APPDATA/opencode/agents"
    $skillsSrc  = "$OCATeamDir/skills/ocat"
    $skillsDest = "$env:APPDATA/opencode/skills/ocat"

    Validate-Sources $agentsSrc $skillsSrc

    New-Item -ItemType Directory -Force -Path $agentsDest  | Out-Null
    New-Item -ItemType Directory -Force -Path $skillsDest  | Out-Null

    Write-Log "Installing agents -> $agentsDest"
    $agentFiles = Get-ChildItem "$agentsSrc/*.md"
    Copy-Item "$agentsSrc/*.md" -Destination $agentsDest -Force
    Write-Log "  $($agentFiles.Count) agent(s) installed"

    Write-Log "Installing skill -> $skillsDest"
    Copy-Item "$skillsSrc/SKILL.md" -Destination $skillsDest -Force
    Write-Log "  ocat skill installed"

    Write-Host ""
    Write-Log "Installation complete!"
    Write-Host ""
    Write-Host "  Next steps:"
    Write-Host "    1. Open any project in OpenCode"
    Write-Host "    2. Press Tab to switch to the 'ocat-orchestrator' agent"
    Write-Host "    3. Describe your project and the orchestrator will handle the rest"
    Write-Host ""
    Write-Host "  To customize models, edit: `$env:APPDATA/opencode/opencode.json"
    Write-Host "    Example override:"
    Write-Host '    { "agent": { "ocat-developer": { "model": "openai/gpt-5" } } }'
}

# ── Install to a project ───────────────────────────────────
function Install-Project {
    param([string]$ProjectPath)

    # Strip trailing slash / backslash
    $ProjectPath = $ProjectPath.TrimEnd(@('/', '\'))

    if (-not (Test-Path $ProjectPath -PathType Container)) {
        Write-Err "Project directory not found: $ProjectPath"
        exit 1
    }

    $agentsSrc  = "$OCATeamDir/agents"
    $agentsDest = "$ProjectPath/.opencode/agents"
    $skillsSrc  = "$OCATeamDir/skills/ocat"
    $skillsDest = "$ProjectPath/.opencode/skills/ocat"

    Validate-Sources $agentsSrc $skillsSrc

    New-Item -ItemType Directory -Force -Path $agentsDest  | Out-Null
    New-Item -ItemType Directory -Force -Path $skillsDest  | Out-Null

    Write-Log "Installing agents -> $agentsDest"
    $agentFiles = Get-ChildItem "$agentsSrc/*.md"
    Copy-Item "$agentsSrc/*.md" -Destination $agentsDest -Force
    Write-Log "  $($agentFiles.Count) agent(s) installed"

    Write-Log "Installing skill -> $skillsDest"
    Copy-Item "$skillsSrc/SKILL.md" -Destination $skillsDest -Force
    Write-Log "  ocat skill installed"

    # Scaffold opencode.json if it doesn't exist
    $snippet    = "$OCATeamDir/scaffold/opencode.json.snippet"
    $ocatConfig = "$OCATeamDir/scaffold/ocat.json.snippet"

    if ((Test-Path $snippet) -and (-not (Test-Path "$ProjectPath/opencode.json"))) {
        Copy-Item $snippet -Destination "$ProjectPath/opencode.json"
        Write-Log "Scaffolded opencode.json"
    }
    elseif ((Test-Path $snippet) -and (Test-Path "$ProjectPath/opencode.json")) {
        Write-Warn "opencode.json already exists — skipped scaffold"
    }

    if ((Test-Path $ocatConfig) -and (-not (Test-Path "$ProjectPath/.ocat.json"))) {
        Copy-Item $ocatConfig -Destination "$ProjectPath/.ocat.json"
        Write-Log "Scaffolded .ocat.json with active agents config"
    }
    elseif ((Test-Path $ocatConfig) -and (Test-Path "$ProjectPath/.ocat.json")) {
        Write-Warn ".ocat.json already exists — skipped scaffold"
    }

    # Ensure .boards/ is gitignored (runtime state, never committed)
    $gitignorePath = "$ProjectPath/.gitignore"
    if (Test-Path $gitignorePath) {
        $gitignoreContent = Get-Content $gitignorePath -Raw -ErrorAction SilentlyContinue
        if (-not ($gitignoreContent -match '(?m)^\.boards/$')) {
            Add-Content -Path $gitignorePath -Value "`n.boards/" -NoNewline:$false
            Write-Log "Added .boards/ to .gitignore"
        }
    }
    else {
        Set-Content -Path $gitignorePath -Value ".boards/"
        Write-Log "Created .gitignore with .boards/"
    }

    Write-Host ""
    Write-Log "Installation complete!"
    Write-Host ""
    Write-Host "  Project: $ProjectPath"
    Write-Host "  Agents:  $agentsDest/"
    Write-Host "  Skill:   $skillsDest/"
    Write-Host ""
    Write-Host "  To customize: edit $ProjectPath/.opencode/agents/*.md"
}

# ── Uninstall from global ──────────────────────────────────
function Uninstall-Global {
    $agentsDest = "$env:APPDATA/opencode/agents"
    $skillsDest = "$env:APPDATA/opencode/skills/ocat"

    Write-Log "Removing ocat agents from $agentsDest"
    Remove-Item -Force -ErrorAction SilentlyContinue "$agentsDest/ocat-*.md"
    Write-Log "Removing ocat skill from $skillsDest"
    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue $skillsDest
    Write-Log "Uninstall complete."
}

# ── Uninstall from project ─────────────────────────────────
function Uninstall-Project {
    param([string]$ProjectPath)

    $ProjectPath = $ProjectPath.TrimEnd(@('/', '\'))
    $agentsDest  = "$ProjectPath/.opencode/agents"
    $skillsDest  = "$ProjectPath/.opencode/skills/ocat"

    Write-Log "Removing ocat agents from $agentsDest"
    Remove-Item -Force -ErrorAction SilentlyContinue "$agentsDest/ocat-*.md"
    Write-Log "Removing ocat skill from $skillsDest"
    Remove-Item -Force -Recurse -ErrorAction SilentlyContinue $skillsDest
    Write-Log "Uninstall complete."
}

# ── Version helper ─────────────────────────────────────────
function Get-OCATeamVersion {
    $versionFile = "$OCATeamDir/VERSION"
    if (Test-Path $versionFile) {
        (Get-Content $versionFile -Raw).Trim()
    }
    else {
        "unknown"
    }
}

# ── Usage / Help ───────────────────────────────────────────
function Show-Usage {
    $ver = Get-OCATeamVersion
    Write-Host "OCATeam v$ver"
    Write-Host ""
    Write-Host "Usage: .\install.ps1 [-Global | -Project <path>] [-Uninstall]"
    Write-Host "       .\install.ps1 -Version"
    Write-Host "       .\install.ps1 -Help"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  -Global              Install OCATeam globally (`$env:APPDATA\opencode\)"
    Write-Host "  -Project <path>      Install OCATeam into a specific project"
    Write-Host "  -Uninstall           Remove a previous installation (use with -Global or -Project)"
    Write-Host "  -Version             Print OCATeam version"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1 -Global"
    Write-Host "  .\install.ps1 -Project C:\code\my-app"
    Write-Host "  .\install.ps1 -Uninstall -Global"
    Write-Host "  .\install.ps1 -Uninstall -Project C:\code\my-app"
}

# ════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════

# Handle -Help / -Version immediately
if ($Help) {
    Show-Usage
    exit 0
}

if ($Version) {
    Write-Host "OCATeam v$(Get-OCATeamVersion)"
    exit 0
}

# Determine mode: -Global and -Project are mutually exclusive
if ($Global -and $Project) {
    Write-Err "Cannot specify both -Global and -Project. Choose one."
    Show-Usage
    exit 1
}

if (-not $Global -and -not $Project) {
    Write-Err "Either -Global or -Project is required."
    Show-Usage
    exit 1
}

if ($Project -and $Project.Trim() -eq "") {
    Write-Err "-Project requires a path argument."
    exit 1
}

# Dispatch
if ($Uninstall) {
    if ($Global)  { Uninstall-Global }
    else          { Uninstall-Project $Project }
}
else {
    if ($Global)  { Install-Global }
    else          { Install-Project $Project }
}
