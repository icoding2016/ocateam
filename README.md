# OCATeam — Multi-Agent Project Delivery Framework

[![Test](https://github.com/icoding2016/ocateam/actions/workflows/test.yml/badge.svg)](https://github.com/icoding2016/ocateam/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.3.0-blue)]()

> 🚀 End-to-end agentic software delivery: requirements → design → implement → test → quality gate.
> Built on OpenCode's multi-agent runtime. One command to install, zero setup per project.

[中文文档](README.zh-CN.md)

---

## What is OCATeam?

OCATeam is a reusable **multi-agent framework** for running end-to-end software projects through OpenCode's agent system. It defines:

- **5 specialized agents**: Orchestrator, Architect, Developer, Reviewer, Explorer
- **5 workflow phases**: Requirements → Design → Implementation → Testing → Quality Gate
- **Document-based coordination**: All agents communicate through board files in `.boards/`
- **Quality gates at every stage**: Implement/refine → review cycle with automatic escalation

**Key insight:** OpenCode supports primary + subagent architecture but doesn't ship orchestration logic. OCATeam encodes the orchestration into agent prompts and a workflow Skill — no external wrapper needed.

## Quick Start

### 1. Install (one-time)

```bash
git clone https://github.com/icoding2016/ocateam.git
cd ocateam

# Global install: agents available in EVERY project
./install.sh --global

# OR: Per-project install (team-shared, version-controlled)
./install.sh --project ~/code/my-app
```

### 2. Project Setup

If you cloned an existing OCATeam project (one that has `.ocat.json` in its root):

```bash
cd my-project
./install.sh --project .    # Install agents + skill
```

The installer copies agents to `.opencode/agents/`, the skill to `.opencode/skills/`, and scaffolds `opencode.json` and `.ocat.json` if they don't exist. See [Auto-approve Permissions](#auto-approve-permissions) for how to skip permission prompts.

### 2. Use

```bash
# Open your project in OpenCode
opencode my-project/

# Press Tab → switch to "ocat-orchestrator"
# Type: "Start a new project: build a CLI tool that..."
```

The orchestrator automatically loads the workflow, plans phases, delegates to specialists, and gates quality — all within OpenCode.

## Architecture

```
User → Orchestrator (primary agent)
         ├── ocat-architect  — system design, no code
         ├── ocat-developer  — implementation + tests
         ├── ocat-reviewer   — quality gate, read-only
         └── ocat-explorer   — research + inspection
```

## Workflow Phases

OCATeam organizes delivery into distinct phases with **mandatory or configurable human approval gates** after each:

| Phase | Owner | Deliverable | Gate |
|-------|-------|-------------|------|
| 0: Requirements Interview | Orchestrator | Requirements doc (`.boards/.../requirements.md`) | 🔒 Mandatory approval |
| 1: System Design + Delivery Plan | Architect → Reviewer + Orchestrator | Design doc + multi-stage delivery plan | 🔒 Mandatory approval |
| 2: Iterative Delivery (N Stages) | Developer → Reviewer (per stage) | Each stage: implemented code + tests + review verdict | 🔓 Configurable (default: required) |
| 3: Final Delivery & Quality Gate | Developer + Reviewer | Integration tests + final review (4 dimensions) + verdict | 🔒 Mandatory approval |

### Per-Stage Activity

Each delivery stage in Phase 2 follows two nested loops:

1. **Developer Loop** (autonomous): `implement → test → fix` — no orchestrator intervention
2. **Reviewer Loop** (max N iterations): `review → [reject] fix → test → re-review` — N configured via `.ocat.json`

After each stage: Stage gate (check `.ocat.json.gates.delivery_stage_approval`) → human approval or auto-proceed.

## Configuration

OCATeam uses two config files:

| File | Purpose |
|------|---------|
| `.ocat.json` | OCATeam workflow config (gates, active agents, review limits) |
| `opencode.json` | Standard OpenCode config (model overrides, agent permissions) |

### `.ocat.json` — Workflow Control

```json
{
  "version": "0.3.0",
  "active_agents": ["architect", "developer", "reviewer", "explorer"],
  "gates": {
    "phase_0_requirements": "mandatory",
    "phase_1_design": "mandatory",
    "delivery_stage_approval": true,
    "phase_3_final": "mandatory"
  },
  "review": {
    "max_iterations": 3
  }
}
```

### Gate Values

| Value | Behavior |
|-------|----------|
| `"mandatory"` | Cannot be disabled. Orchestrator MUST call `confirm_with_user()`. |
| `true` | Enabled by default, can be set to `false`. |
| `false` | Disabled by default, can be set to `true`. |

- Phase 0, 1, 3 gates are always mandatory (requirements/design/final delivery are too critical to bypass)
- `delivery_stage_approval` controls per-stage human approval (default: required)

### Auto-approve Permissions

The orchestrator agent file uses `bash: ask` — all bash commands prompt for approval.

To skip prompts for trusted workflows, use OpenCode's built-in auto-approve:

| Method | How |
|---|---|
| **CLI startup** | `opencode --auto` or `opencode run --auto "..."` |
| **TUI runtime** | `ctrl+p` → command palette → search "auto-approve" → toggle on |

Auto mode auto-approves all `ask` requests. Explicit `deny` rules are still enforced.
The toggle is per-session and not persisted across restarts.

> **Note:** Inline `opencode.json` agent permissions do NOT override agent file permissions.
> All orchestrator permissions are set directly in `agents/ocat-orchestrator.md`.
> See `doc/design.md §11.10` for details.

### Review Limit

```json
{
  "review": {
    "max_iterations": 3
  }
}
```

Controls how many review→fix cycles are allowed per stage before escalation. Default: 3.

### Agent Activation

```json
{
  "active_agents": ["architect", "developer", "reviewer", "explorer"]
}
```

- Remove entries to deactivate agents for a specific project
- If `.ocat.json` is absent (global install), all agents are active

### Model Overrides (`opencode.json`)

Override agent models in the standard OpenCode config:

```json
{
  "agent": {
    "ocat-developer": { "model": "openai/gpt-5" }
  }
}
```

> **Why two config files?** `opencode.json` is validated against OpenCode's schema, which rejects unknown keys. OCATeam workflow configuration (gates, active agents, review limits) lives in `.ocat.json` to avoid schema conflicts, while model overrides use the standard OpenCode config.

## Project Structure

```
ocat/
├── agents/                  # Agent role definitions (YAML frontmatter + Markdown)
│   ├── ocat-orchestrator.md
│   ├── ocat-architect.md
│   ├── ocat-developer.md
│   ├── ocat-reviewer.md
│   └── ocat-explorer.md
├── skills/ocat/SKILL.md    # Workflow skill (phase definitions, templates, policies)
├── scaffold/                # Per-project scaffold templates
│   ├── opencode.json.snippet
│   └── ocat.json.snippet
├── install.sh               # One-command installer (global + per-project)
├── install.ps1              # PowerShell installer (Windows)
├── scripts/                 # Utility scripts
│   ├── migrate-v0.2.sh      # Migration from v0.1.x to v0.2.x directory layout
│   └── view-log.sh          # Execution log viewer (NDJSON)
├── tests/                   # Test suite
│   ├── validate.sh          # Tier 1: 32 static validation checks
│   ├── test_install.bats    # Tier 2: 17 functional tests for install.sh
│   ├── test_install.ps1     # Tier 2: 21 Pester tests for install.ps1
│   └── tier3_results.md     # Tier 3: POC integration test results
├── Makefile                 # make validate, make test, make install-test
└── doc/                     # Design documents
    ├── prj_goal.md
    ├── design.md
    └── test_plan.md
```

## Testing

```bash
make validate        # Tier 1: Static validation (23 checks, <1s)
make install-test    # Tier 2: Installer functional tests (requires bats)
make test            # All tests (validate + install-test)
```

POC verified end-to-end: all phases completed on a `hello-cli` test project. See `tests/tier3_results.md`.

## Requirements

- **OpenCode** v1.17+ (multi-agent support)
- **Python 3** (for validation scripts)
- **bats-core** (optional, for Tier 2 tests)

## License

Apache 2.0
