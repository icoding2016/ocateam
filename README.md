# OCATeam — Multi-Agent Project Delivery Framework

> 🚀 End-to-end agentic software delivery: requirements → design → implement → test → quality gate.
> Built on OpenCode's multi-agent runtime. One command to install, zero setup per project.

[中文文档](README.zh-CN.md)

---

## What is OCATeam?

OCATeam is a reusable **multi-agent framework** for running end-to-end software projects through OpenCode's agent system. It defines:

- **5 specialized agents**: Orchestrator, Architect, Developer, Reviewer, Explorer
- **5 workflow phases**: Requirements → Design → Implementation → Testing → Quality Gate
- **Document-based coordination**: All agents communicate through board files in `boards/`
- **Quality gates at every stage**: Implement/refine → review cycle with automatic escalation

**Key insight:** OpenCode supports primary + subagent architecture but doesn't ship orchestration logic. OCATeam encodes the orchestration into agent prompts and a workflow Skill — no external wrapper needed.

## Quick Start

### 1. Install (one-time)

```bash
git clone https://github.com/YOUR_ORG/ateam.git
cd ateam

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

| Phase | Owner | Deliverable |
|-------|-------|-------------|
| 0: Requirements | Orchestrator | Clarified requirements in master board |
| 1: Design | Architect → Reviewer | Design doc, reviewed & approved |
| 2: Implementation | Developer → Reviewer | Code + tests, gated by review cycle |
| 3: Testing | Developer → Reviewer | Test results + fixes, coverage verified |
| 4: Quality Gate | Reviewer | Final verdict against original requirements |

Each implementation task runs through an **Implement/Refine → Review** cycle (max 3 iterations before escalation to user).

## Configuration

### Agent Activation (`ocat.json`)

Per-project installs scaffold an `ocat.json` to control which subagents are active:

```json
{
  "active_agents": ["architect", "developer", "reviewer", "explorer"]
}
```

- Remove entries to deactivate agents for a specific project
- If `ocat.json` is absent (global install), all agents are active

### Model Overrides (`opencode.json`)

Override agent models in the standard OpenCode config:

```json
{
  "agent": {
    "ocat-developer": { "model": "openai/gpt-5" }
  }
}
```

> **Why two config files?** `opencode.json` is validated against OpenCode's schema, which rejects unknown keys. OCATeam config lives in `ocat.json` to avoid schema conflicts.

## Project Structure

```
ateam/
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
