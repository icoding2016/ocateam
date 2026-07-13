---
name: ocat
version: 0.2.0
description: "Multi-agent orchestration for end-to-end project delivery. Use when: (1) the active agent is ocat-orchestrator, (2) user mentions ocat agents (ocat-developer, ocat-reviewer, ocat-architect, ocat-explorer), (3) starting a new software project, (4) running a multi-phase development workflow with quality gates, (5) needing phase planning or subagent delegation. Triggers: 'ocat', 'orchestrator', 'multi-agent workflow', 'project delivery', 'design → implement → review'."
license: MIT
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

### Phase 0: Requirement Understanding
**Goal**: Fully understand what the user wants to build.
**Owner**: Orchestrator (with Explorer support)
**Deliverable**: Clarified requirements documented in `.boards/orchestrator/<project>/board.md`

- Orchestrator asks clarifying questions
- Explorer researches existing solutions, libraries, precedents
- Output: clear, testable requirements with scope boundaries

### Hard Confirmation Gate (After Phase 0)

**MANDATORY**: Before proceeding to Phase 1, the Orchestrator MUST obtain explicit user approval.

**Process:**
1. Present requirements summary to user
2. Present implementation plan (phases, subagents, estimated complexity)
3. Wait for explicit user response:
   - "Yes" / "Proceed" / "Approve" → Continue to Phase 1
   - "No" / "Cancel" → Stop workflow
   - "Modify" / "Change" → Revise requirements, loop back to step 1

**Confirmation Template:**
```
## Implementation Plan

### Requirements Summary
[What will be built]

### Implementation Approach
- Phase 1: Design — [description]
- Phase 2: Implementation — [description]
- Phase 3: Testing — [description]
- Phase 4: Quality Gate — [description]

### Subagents to be Involved
- ocat-architect: [role]
- ocat-developer: [role]
- ocat-reviewer: [role]

**Do you approve this plan? (yes/no/modify)**
```

**This is a HARD GATE** — the orchestrator cannot proceed without explicit user approval. This is the only mandatory confirmation in the entire workflow.

### Phase 1: System Design
**Goal**: Produce a reviewable design document.
**Owner**: Orchestrator → Architect
**Deliverable**: Design document in `.boards/architect/<task_id>/board.md`

- Architect analyzes requirements
- Architect produces: system overview, component diagram, API specs, data models, technology choices
- Reviewer reviews design → APPROVED or NEEDS_REVISION

### Phase 2: Implementation
**Goal**: Implement features per the approved design.
**Owner**: Orchestrator → Developer
**Deliverable**: Working code with tests, progress in `.boards/developer/<task_id>/board.md`

- Developer implements one task at a time (tasks decomposed from design)
- Developer writes tests alongside implementation
- Each task goes through the Implement/Refine → Review cycle

### Phase 3: Testing & Debugging
**Goal**: Verify correctness and fix issues.
**Owner**: Orchestrator → Developer (test focus)
**Deliverable**: Test results + fixes in `.boards/developer/<task_id>/board.md`

- Developer runs full test suite and reports results to task board
- Developer fixes failing tests, with each fix going through the Implement/Refine → Review cycle
- Reviewer verifies test coverage and quality (APPROVED / NEEDS_REVISION)
- MAX_REVIEW_ITERATIONS applies per fix iteration (escalate after 3 without APPROVED)

### Phase 4: Quality Gate
**Goal**: Final verification against original requirements.
**Owner**: Orchestrator → Reviewer
**Deliverable**: Final review verdict in `.boards/reviewer/<task_id>/board.md`

- Reviewer applies all four review dimensions:
  - **First-Principles Review**: question every element from fundamentals
  - **User-Value Alignment**: check for deviation, omission, over-engineering
  - **Requirement Traceability**: every output must trace to a user requirement
  - **Contamination Detection**: flag anything that doesn't belong to this project's ecosystem
- Final verdict: APPROVED or NEEDS_REVISION

---

## Implement/Refine → Review Cycle

Every implementation task follows this cycle:

```
1. Orchestrator defines task → delegates to Developer via Task tool
2. Developer implements + updates its task board
3. Orchestrator delegates to Reviewer via Task tool
4. Reviewer evaluates against all four review dimensions:
   - **First-Principles Review**: question every element from fundamentals
   - **User-Value Alignment**: check deviation, omission, and over-engineering from the user's perspective
   - **Requirement Traceability**: every output element must trace to a requirement
   - **Contamination Detection**: flag cross-project/platform elements that don't belong
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

---

## Activation Config

The Orchestrator reads a project's `.ocat.json` to determine which subagents are active:

```json
{
  "active_agents": ["architect", "developer", "reviewer", "explorer"]
}
```

- Only agents in `active_agents` are eligible for delegation
- The effective set is the intersection of `active_agents` and the orchestrator's `permission.task` allowlist
- If `.ocat.json` is absent, all agents in the allowlist are active
- Remove entries from the list to deactivate unused agents for a project

---

## Agent Roles Summary

| Agent | Mode | Purpose | Thinking | Can Edit | Can Bash |
|-------|------|---------|----------|----------|----------|
| ocat-orchestrator | primary | Plan, delegate, gate, escalate | high | ask | ask |
| ocat-architect | subagent | System design, no code | high | allow | deny |
| ocat-developer | subagent | Implementation + tests | high | allow | allow |
| ocat-reviewer | subagent | Quality gate, read-only | high | deny | deny |
| ocat-explorer | subagent | Research, inspection | medium | deny | deny |

> **About thinking configuration:** Each agent declares its intended thinking/reasoning level via the `thinking` frontmatter field. This is currently declarative (routed to `options.thinking`) — it documents intent but does not yet drive model behavior across all providers. For unified thinking level support, track [OpenCode Issue #33013](https://github.com/opencode-ai/opencode/issues/33013) (effort ladder design). In the meantime, provider-specific thinking can be configured in `opencode.json` under `provider.<name>.models.<model>.options`.

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
{"ts":"<ISO 8601>","phase":<0-4>,"action":"<action>","agent":"<agent>","msg":"<message>"}
```

See `doc/execution-log-format.md` for full schema and examples.

---

## Interaction Strategy

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
