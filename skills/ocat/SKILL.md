---
name: ocat
version: 0.3.0
description: "Multi-agent orchestration for end-to-end project delivery. Use when: (1) the active agent is ocat-orchestrator, (2) user mentions ocat agents (ocat-developer, ocat-reviewer, ocat-architect, ocat-explorer), (3) starting a new software project, (4) running a multi-phase development workflow with quality gates, (5) needing phase planning or subagent delegation. Triggers: 'ocat', 'orchestrator', 'multi-agent workflow', 'project delivery', 'design → implement → review'."
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: multi-agent
---

# OCATeam — Multi-Agent Project Delivery Workflow

## Overview

OCATeam provides a structured, document-based workflow for running end-to-end software projects through OpenCode's multi-agent system. An Orchestrator (primary agent) coordinates four worker subagents (Architect, Developer, Reviewer, Explorer) through distinct phases with quality gates at every stage.

## When to Use

Load this skill when:
- Starting a new software project from requirements
- Running a multi-phase development workflow
- Need structured quality gating and review cycles
- Want document-based coordination between agents
- The active agent is ocat-orchestrator or any ocat-* agent

## Project Initialization

When starting a new OCAT workflow in a project, the Orchestrator MUST:

1. **Ensure `.boards/` is gitignored** — The `.boards/` directory contains runtime state and should never be committed. Add `.boards/` to the project's `.gitignore` if not already present:
   ```bash
   if [ -f .gitignore ]; then
     grep -qxF '.boards/' .gitignore || echo '.boards/' >> .gitignore
   else
     echo '.boards/' > .gitignore
   fi
   ```

2. **Create the board directory structure**:
   ```
   .boards/
   ├── orchestrator/<project_name>/board.md
   ├── developer/
   ├── reviewer/
   ├── architect/
   └── explorer/
   ```

3. **Verify `.ocat.json` exists** — If not, scaffold it from `scaffold/ocat.json.snippet` (if available) or create a default with all agents active.

This initialization happens in Phase 0, before any subagent delegation.

## Architecture

```
User → Orchestrator (primary)
         ├── ocat-architect (subagent) — system design
         ├── ocat-developer (subagent) — implementation + tests
         ├── ocat-reviewer  (subagent) — quality gate
         └── ocat-explorer  (subagent) — research + inspection
```

All coordination is document-based via board files in `.boards/`. Agents share the project workspace.

---

## Phase Structure

### Phase 0: Requirements Interview
**Goal**: Conduct structured interview to fully understand what the user wants to build.
**Owner**: Orchestrator (with Explorer support)
**Deliverable**: Requirements document in `.boards/orchestrator/<project>/requirements.md`

- Orchestrator conducts structured interview with user using OpenCode's `question` tool
- Questions cover: project name/type, core features, tech constraints, non-functional requirements
- Explorer researches existing solutions, libraries, precedents
- Output: clear, testable requirements with scope boundaries

#### Question Template

```markdown
1. What is the project name and type? (CLI / Web / API / Library)
2. What are the core features? (list top 3-5)
3. What are the technical constraints? (language, framework, platform)
4. What are the non-functional requirements? (performance, security, scalability)
5. Are there any existing systems or codebases to consider?
6. What is the timeline or priority?
```

- **Gate**: confirm_with_user() — MANDATORY

### Phase 1: System Design + Delivery Plan
**Goal**: Produce a reviewable design document and delivery plan.
**Owner**: Orchestrator → Architect
**Deliverable**: Design document in `.boards/architect/<task_id>/board.md` + delivery plan in `.boards/orchestrator/<project>/delivery-plan.md`

- Architect produces: system design document AND delivery plan (implementation stages)
- Reviewer evaluates both for quality (4 dimensions: first-principles, user-value, traceability, contamination)
- Orchestrator evaluates delivery plan for **execution feasibility** (stage sizing, ordering, dependencies)
- Both reviews must pass before Phase 1 gate

**Gate**: confirm_with_user() — MANDATORY

### Phase 2: Iterative Delivery
**Goal**: Implement features per approved design through multiple delivery stages.
**Owner**: Orchestrator → Developer + Reviewer
**Deliverable**: Working code with tests, progress tracked in delivery plan

- Multiple delivery stages, each stage follows this pattern:
  1. Developer autonomous loop: implement → test → fix (orchestrator does NOT interrupt)
  2. Reviewer loop: review → if NEEDS_REVISION → fix → test → re-review (max N iterations configurable)
  3. If APPROVED: check gates.delivery_stage_approval
     - true/absent → confirm_with_user() before next stage
     - false → log_and_proceed()
  4. If max iterations reached without APPROVED → escalate to user
- Orchestrator tracks stages via `.boards/orchestrator/<project>/delivery-plan.md`
- After all stages complete → proceed to Phase 3

### Phase 3: Final Delivery & Quality Gate
**Goal**: Integration testing / final verification against original requirements.
**Owner**: Orchestrator → Developer + Reviewer
**Deliverable**: Fully tested, reviewed project

- Integration testing (full suite)
- Final Review by Reviewer applying all four review dimensions:
  - **First-Principles Review**: question every element from fundamentals
  - **User-Value Alignment**: check for deviation, omission, over-engineering
  - **Requirement Traceability**: every output must trace to a user requirement
  - **Contamination Detection**: flag anything that doesn't belong to this project's ecosystem
- Review verdict: APPROVED or NEEDS_REVISION
- **Gate**: confirm_with_user() — MANDATORY
- Project delivered

---

## Configurable Gate System

Gates control where user confirmation is required. Configured via `.ocat.json`:

```json
{
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

### Gate Value Semantics

| Value | Behavior |
|-------|----------|
| `"mandatory"` | Cannot be disabled. Orchestrator MUST call confirm_with_user() |
| `true` | Enabled by default, can be set to false |
| `false` | Disabled by default, can be set to true |

**Gate behavior**: orchestrator checks `.ocat.json.gates` before each gate decision.

---

## Developer Loop

Developer operates autonomously with no maximum iterations:

```
1. Developer implements feature
2. Developer runs tests
3. Developer fixes failures
4. Developer reports completion when ready
```

## Reviewer Loop

Reviewer operates with configurable maximum iterations:

```
1. Reviewer evaluates against 4 dimensions:
   - **First-Principles Review**: question every element from fundamentals
   - **User-Value Alignment**: check deviation, omission, and over-engineering from the user's perspective
   - **Requirement Traceability**: every output element must trace to a requirement
   - **Contamination Detection**: flag cross-project/platform elements that don't belong
2. If NEEDS_REVISION → developer fixes → test → re-review
3. If max iterations hit → escalate to user
4. If APPROVED → stage gate check → proceed
```

MAX_REVIEW_ITERATIONS is configured via `.ocat.json.review.max_iterations` (default 3).

---

## Document-Based Coordination

### Board File Layout

```
.boards/
├── orchestrator/
│   └── <project_name>/
│       └── board.md          # Master project board
├── explorer/
│   └── <task_id>/
│       └── board.md          # Exploration findings
├── architect/
│   └── <task_id>/
│       └── board.md          # Design documents
├── developer/
│   └── <task_id>/
│       └── board.md          # Implementation progress
└── reviewer/
    └── <task_id>/
        └── board.md          # Review verdicts
```

### Master Board Template (`.boards/orchestrator/<project>/board.md`)

```markdown
# Project: <project_name>

## Status
- Current Phase: <Phase 0-3>
- Started: <timestamp>
- Last Updated: <timestamp>

## Requirements Summary
[Clarified requirements from Phase 0]

## Phase Progress

### Phase 0: Requirements ✅/🔄/⏳
- [ ] Clarify user requirements
- [ ] Research existing solutions (Explorer)
- [ ] Document requirements

### Phase 1: Design
- [ ] Produce design document (Architect)
- [ ] Review design (Reviewer)
- [ ] Address review feedback
- [ ] Design approved

### Phase 2: Iterative Delivery (Stage N of M)
- Stage: <name>
  - [ ] Developer loop: implement → test → fix
  - [ ] Reviewer loop: review → fix → re-review
  - [ ] Stage gate: [pending/approved/skipped]

### Phase 3: Final Delivery & Quality Gate
- [ ] Integration test
- [ ] Final Review (4 dimensions: first-principles, user-value, traceability, contamination)
- [ ] 🔒 Final gate: [pending/approved]

## Decisions Log
- <timestamp>: <decision> — <rationale>

## Escalations
- <timestamp>: <issue> — <resolution>
```

### Task Board Template (`.boards/developer/<task_id>/board.md`)

```markdown
# Task: <task_id> — <task_name>

## Objective
[What this task implements, linked to design doc section]

## Progress
- [ ] Implementation
- [ ] Unit tests
- [ ] Integration tests
- [ ] Self-review

## Changes Made
- <file_path>: <description of change>

## Test Results
```
<test output>
```

## Issues / Notes
- [Issue or observation]
```

## Requirements: <project>

### Overview
- Type: CLI / Web / API / Library
- Primary goal: ...

### Core Features
1. Feature A — description

### Non-Functional Requirements
- Performance: ...
- Security: ...

### Technical Constraints
- Language: ...
- Framework: ...

### Priorities
1. P0: ...

---

## Activation Config

The Orchestrator reads a project's `.ocat.json` to determine which subagents are active:

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

- Only agents in `active_agents` are eligible for delegation
- The effective set is the intersection of `active_agents` and the orchestrator's `permission.task` allowlist
- If `.ocat.json` is absent, all agents in the allowlist are active
- Remove entries from the list to deactivate unused agents for a project
- For auto-approve permissions, use OpenCode's built-in mechanism: `opencode --auto` (CLI) or `ctrl+p` → command palette → toggle (TUI)

---

## Agent Roles Summary

| Agent | Mode | Purpose | Permission Model |
|---|---|---|---|
| ocat-orchestrator | primary | PM + Coordinator: interview, delegate, gate, track | balanced (see §11.10) |
| ocat-architect | subagent | System design + delivery plan | edit allow, bash deny |
| ocat-developer | subagent | Implementation + tests | edit allow, bash allow |
| ocat-reviewer | subagent | Quality gate, read-only | edit deny, bash deny |
| ocat-explorer | subagent | Research, inspection | edit deny, bash deny |

---

## Communication Conventions

1. **Orchestrator always updates the master board** before delegating to the next subagent
2. **Subagents write outputs to their board file** — not to the chat directly
3. **Orchestrator reads board files** to track progress and make decisions
4. **All agents reference file paths** (not copying full content into chat)
5. **Reviewer is the final word** on quality — if APPROVED, the Orchestrator proceeds; if NEEDS_REVISION, the Orchestrator re-delegates

---

## Escalation Policy

The Orchestrator escalates to the user when:
1. **Review cycle exhausted**: MAX_REVIEW_ITERATIONS reached without APPROVED
2. **Ambiguous requirements**: Cannot clarify with the user's input alone
3. **Architecture conflicts**: Developer needs to diverge from design
4. **Resource limits**: Agent step caps reached before completion
5. **User interrupts**: User can intervene at any time in the primary session

Escalation format:
```
## Escalation: <reason>

### What was happening
[Summary of current phase and task]

### What went wrong
[Specific issue or blocker]

### Recommended path forward
[Orchestrator's suggestion]

### Options for user
1. [Option 1]
2. [Option 2]

---

## Execution Logging

The orchestrator is responsible for ALL execution logging. Subagents with `bash: allow` (developer) can log directly. Subagents with `bash: deny` (architect, reviewer, explorer) have their activities logged by the orchestrator reading their board files.

### Direct Logging (Orchestrator + Developer)

Use bash to append to the log file:
```bash
echo '{"ts":"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'","phase":0,"action":"phase_start","agent":"ocat-orchestrator","msg":"Phase 0: Requirements analysis"}' >> .boards/execution.log
```

### Indirect Logging (Orchestrator logs on behalf of Architect, Reviewer, Explorer)

When a subagent with `bash: deny` completes a task:
1. Read their board file at `.boards/<agent>/<task_id>/board.md`
2. Log the completion with subagent name, task ID, and outcome

Example:
```bash
echo '{"ts":"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'","phase":2,"action":"task_complete","agent":"ocat-orchestrator","msg":"Developer completed task dev-001","details":{"subagent":"ocat-developer","task_id":"dev-001","outcome":"success"}}' >> .boards/execution.log
```

### When to Log
- Session start/end
- Phase start/complete
- Task delegation
- Review start/complete
- User confirmation
- Escalation

### Log Format
Each entry is a JSON object:
```json
{"ts":"<ISO 8601>","phase":<0-3>,"action":"<action>","agent":"<agent>","msg":"<message>"}
```

See `doc/execution-log-format.md` for full schema and examples.

---

## Interaction Strategy

The interaction strategy is now configured via the `.ocat.json` gate system (§11.12).
The decision tree below provides additional guidance for orchestrator communication style within phases.

The workflow uses a dual-mode interaction strategy to balance quality assurance with execution speed.

### Plan Mode (Phase 0-1: Requirements & Design)

**Strict confirmation at every key decision.**

- Requirements must be explicitly approved by user
- Scope boundaries must be confirmed
- Design must be reviewed and approved
- No autonomous execution

**When to confirm:**
- After initial requirements gathering
- After scope definition
- After design completion (hard gate)
- Before proceeding to implementation

### Smart Mode (Phase 2-3: Implementation & Testing)

**Orchestrator judges when to ask for confirmation.**

**Always confirm:**
- Architecture changes
- Multi-module changes
- Breaking changes
- Security-sensitive changes
- Changes affecting > 3 files

**Execute then report:**
- Medium complexity tasks (30 min - 2 hr estimated)
- Changes affecting 2-3 files
- Non-breaking refactors

**Execute directly:**
- Simple tasks (< 30 min estimated)
- Single-file changes
- Bug fixes with clear root cause
- Test additions
- Documentation updates

### Decision Tree

```
Is this an architecture change?
  ├─ YES → Confirm with user
  └─ NO → Does it affect > 3 files?
              ├─ YES → Confirm with user
              └─ NO → Is it security-sensitive?
                        ├─ YES → Confirm with user
                        └─ NO → Estimated effort > 2 hours?
                                  ├─ YES → Execute then report
                                  └─ NO → Estimated effort > 30 min?
                                            ├─ YES → Execute then report
                                            └─ NO → Execute directly
```

### Configuration

Projects can override the interaction strategy in `.ocat.json`:

```json
{
  "interaction_mode": "smart",
  "confirm_threshold": 3
}
```

- `"strict"`: Always confirm before execution (even in Phase 2-3)
- `"smart"`: Use the decision tree above (default)
- `confirm_threshold`: Override the file count threshold (default: 3)

### Examples

**Example 1: Simple bug fix**
- User: "Fix the login bug in auth.js"
- Orchestrator: Executes directly (single file, < 30 min)
- Result: "Fixed login bug in auth.js. Test passed."

**Example 2: Medium refactor**
- User: "Refactor the database layer"
- Orchestrator: Executes then reports (2-3 files, 1-2 hr)
- Result: "Refactored database layer across db.js, models.js, queries.js. All tests passed."

**Example 3: Architecture change**
- User: "Switch from REST to GraphQL"
- Orchestrator: Confirms first (architecture change)
- Result: "I'll switch from REST to GraphQL. This will affect: api/, resolvers/, schema/. Proceed? (yes/no)"
```
