---
name: ateam
description: Multi-agent workflow for end-to-end project delivery (requirement analysis → design → implement/test/debug → quality gating). Use when starting a new software project, running through a full development lifecycle, or when the orchestrator needs workflow context for phase planning and delegation.
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: multi-agent
---

# ATEAM — Multi-Agent Project Delivery Workflow

## Overview

ATEAM provides a structured, document-based workflow for running end-to-end software projects through OpenCode's multi-agent system. An Orchestrator (primary agent) coordinates four worker subagents (Architect, Developer, Reviewer, Explorer) through distinct phases with quality gates at every stage.

## When to Use

Load this skill when:
- Starting a new software project from requirements
- Running a multi-phase development workflow
- Need structured quality gating and review cycles
- Want document-based coordination between agents

## Architecture

```
User → Orchestrator (primary)
         ├── ateam-architect (subagent) — system design
         ├── ateam-developer (subagent) — implementation + tests
         ├── ateam-reviewer  (subagent) — quality gate
         └── ateam-explorer  (subagent) — research + inspection
```

All coordination is document-based via board files in `boards/`. Agents share the project workspace.

---

## Phase Structure

### Phase 0: Requirement Understanding
**Goal**: Fully understand what the user wants to build.
**Owner**: Orchestrator (with Explorer support)
**Deliverable**: Clarified requirements documented in `boards/orchestrator/<project>/board.md`

- Orchestrator asks clarifying questions
- Explorer researches existing solutions, libraries, precedents
- Output: clear, testable requirements with scope boundaries

### Phase 1: System Design
**Goal**: Produce a reviewable design document.
**Owner**: Orchestrator → Architect
**Deliverable**: Design document in `boards/architect/<task_id>/board.md`

- Architect analyzes requirements
- Architect produces: system overview, component diagram, API specs, data models, technology choices
- Reviewer reviews design → APPROVED or NEEDS_REVISION

### Phase 2: Implementation
**Goal**: Implement features per the approved design.
**Owner**: Orchestrator → Developer
**Deliverable**: Working code with tests, progress in `boards/developer/<task_id>/board.md`

- Developer implements one task at a time (tasks decomposed from design)
- Developer writes tests alongside implementation
- Each task goes through the Implement/Refine → Review cycle

### Phase 3: Testing & Debugging
**Goal**: Verify correctness and fix issues.
**Owner**: Orchestrator → Developer (test focus)
**Deliverable**: Test results + fixes in `boards/developer/<task_id>/board.md`

- Developer runs full test suite
- Developer fixes failing tests
- Reviewer verifies test coverage and quality

### Phase 4: Quality Gate
**Goal**: Final verification against original requirements.
**Owner**: Orchestrator → Reviewer
**Deliverable**: Final review verdict in `boards/reviewer/<task_id>/board.md`

- Reviewer checks: all requirements met, tests pass, no regressions, documentation complete
- Final verdict: APPROVED or NEEDS_REVISION

---

## Implement/Refine → Review Cycle

Every implementation task follows this cycle:

```
1. Orchestrator defines task → delegates to Developer via Task tool
2. Developer implements + updates its task board
3. Orchestrator delegates to Reviewer via Task tool
4. Reviewer evaluates against: task goal, project goals, original requirements
5. Reviewer writes verdict → APPROVED / NEEDS_REVISION
6. If APPROVED → Orchestrator proceeds to next task/phase
7. If NEEDS_REVISION → Orchestrator re-delegates to Developer with Reviewer's feedback
8. Loop to step 2
```

**MAX_REVIEW_ITERATIONS = 3**. After 3 iterations without APPROVED:
- Orchestrator STOPS and escalates to the user
- Include: summary of what was attempted, last Reviewer feedback, recommended path forward
- User decides: override and proceed, redefine requirements, or abandon

---

## Document-Based Coordination

### Board File Layout

```
boards/
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

### Master Board Template (`boards/orchestrator/<project>/board.md`)

```markdown
# Project: <project_name>

## Status
- Current Phase: <Phase 0-4>
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

### Phase 2: Implementation
- Task: <task_name>
  - [ ] Implement (Developer)
  - [ ] Write tests (Developer)
  - [ ] Review (Reviewer) — iteration 1
  - [ ] Address feedback
  - [ ] Review (Reviewer) — iteration 2

### Phase 3: Testing
- [ ] Run full test suite
- [ ] Fix failures
- [ ] Review test coverage

### Phase 4: Quality Gate
- [ ] Final review against requirements
- [ ] All gates passed

## Decisions Log
- <timestamp>: <decision> — <rationale>

## Escalations
- <timestamp>: <issue> — <resolution>
```

### Task Board Template (`boards/developer/<task_id>/board.md`)

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

---

## Activation Config

The Orchestrator can read a project's `opencode.json` to determine which agents are active:

```json
{
  "ateam": {
    "active_agents": ["orchestrator", "architect", "developer", "reviewer", "explorer"]
  }
}
```

- Only agents in `active_agents` are eligible for delegation
- The effective set is the intersection of `active_agents` and the orchestrator's `permission.task` allowlist
- If `active_agents` is absent, all agents in the allowlist are active
- Remove entries from the list to deactivate unused agents for a project

---

## Agent Roles Summary

| Agent | Mode | Purpose | Can Edit | Can Bash |
|-------|------|---------|----------|----------|
| ateam-orchestrator | primary | Plan, delegate, gate, escalate | ask | ask |
| ateam-architect | subagent | System design, no code | allow | deny |
| ateam-developer | subagent | Implementation + tests | allow | allow |
| ateam-reviewer | subagent | Quality gate, read-only | deny | deny |
| ateam-explorer | subagent | Research, inspection | deny | deny |

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
```
