# OCATeam — Multi-Agent Project Delivery Framework

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
git clone https://github.com/YOUR_ORG/ocateam.git
cd ocateam

# Global install: agents available in EVERY project
./install.sh --global

# OR: Per-project install (team-shared, version-controlled)
./install.sh --project ~/code/my-app
```

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
| 3: Final Delivery | Developer + Reviewer | Integration tests + final review verdict | 🔒 Mandatory approval |

### Per-Stage Activity

Each delivery stage in Phase 2 follows two nested loops:

1. **Developer Loop** (autonomous): `implement → test → fix` — no orchestrator intervention
2. **Reviewer Loop** (max N iterations): `review → [reject] fix → test → re-review` — N configured via `.ocat.json`

After each stage: Stage gate (check `.ocat.json.gates.delivery_stage_approval`) → human approval or auto-proceed.

## Configuration

OCATeam uses two config files:

| File | Purpose |
|------|---------|
| `.ocat.json` | OCATeam workflow config (gates, permission mode, review limits) |
| `opencode.json` | Standard OpenCode config (model overrides, agent permissions) |

### `.ocat.json` — Workflow Control

```json
{
  "version": "0.3.0",
  "active_agents": ["architect", "developer", "reviewer", "explorer"],
  "permission_mode": "balanced",
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

### Permission Modes

The orchestrator has three permission profiles, controlled by `permission_mode` in `.ocat.json`:

| Mode | Orchestrator Permission | Use Case |
|------|------------------------|----------|
| `strict` | `bash: ask`, `edit: ask` | High-security environments |
| `balanced` | Granular bash patterns (grep/cat/find/ls/git/echo/cp/file auto-allowed, other commands prompt) | Normal development (**default**) |
| `auto` | `bash: allow`, `edit: allow` | Trusted, fast-paced workflows |

To change the permission mode, use **either** method:

**Method 1 — Automated (recommended):**
```bash
# During initial install:
./install.sh --project ~/code/my-app --permission-mode auto

# After install, to switch modes:
./install.sh --project . --permission-mode strict
```

This updates `.ocat.json` and generates the `opencode.json` override in one step.
No full re-install needed — it only syncs the configuration.

**Method 2 — Manual:**
```bash
# Edit .ocat.json and change permission_mode:
#   "permission_mode": "auto"

# Then edit opencode.json to add the corresponding override:
#   { "agent": { "ocat-orchestrator": { "permission": { "bash": "allow", "edit": "allow" } } } }
```

Both files are in the project root. The manual approach gives you full control.

**Note for `auto` and `strict` modes:**
OpenCode reads permission overrides from `opencode.json` (not `.ocat.json`). The installer bridges the gap by reading `.ocat.json`'s `permission_mode` and writing the corresponding override into `opencode.json`. In `balanced` mode, the agent's built-in defaults are sufficient and no override is needed.

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

> **Why two config files?** `opencode.json` is validated against OpenCode's schema, which rejects unknown keys. OCATeam config lives in `.ocat.json` to avoid schema conflicts. The installer handles permission mode overrides via `opencode.json`'s `agent.<name>.permission` field, which is OpenCode-native.

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
├── tests/                   # Test suite
│   ├── validate.sh          # Tier 1: 23 static validation checks
│   ├── test_install.bats    # Tier 2: 17 functional tests for install.sh
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
make test            # All tests
```

POC verified end-to-end: all 5 phases completed on a `hello-cli` test project. See `tests/tier3_results.md`.

## Requirements

- **OpenCode** v1.17+ (multi-agent support)
- **Python 3** (for validation scripts)
- **bats-core** (optional, for Tier 2 tests)

## License

MIT
