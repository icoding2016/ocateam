# OCATeam Test Plan

**Date:** 2026-07-10
**Status:** Phase 1 & 2 implemented; Phase 3 & 4 planned

---

## 1. Testing Context

OCATeam is "meta-software" — agent definitions (Markdown + YAML frontmatter), workflow configuration (a Skill file), and an installer shell script. There is no application code to unit-test. The testing strategy focuses on:

- **Correctness of configuration files** (valid YAML/JSON, required fields, internal consistency)
- **Correctness of the installer** (files land in right places, edge cases handled)
- **Behavioral correctness** (does the multi-agent workflow actually work in OpenCode)

---

## 2. Test Pyramid

```
       ╱  Tier 4: Semantic / Prompt Quality  ╲    Manual review, infrequent
      ╱────────────────────────────────────────╲
     ╱   Tier 3: Integration / POC              ╲   Real OpenCode + LLM runs
    ╱────────────────────────────────────────────╲   Expensive, pre-release only
   ╱    Tier 2: Functional (install.sh)           ╲   bats tests, mocked env
  ╱────────────────────────────────────────────────╲
 ╱     Tier 1: Static Validation (lint)              ╲   Shell/Python, zero cost
╱──────────────────────────────────────────────────────╲  CI-friendly, per-commit
```

---

## 3. Tier 1: Static Validation

**Goal:** Catch regressions in seconds with zero runtime cost. Runs in CI on every commit.

**Implementation:** `tests/validate.sh`

| Check | Description |
|---|---|
| Bash syntax | `install.sh` passes `bash -n` |
| YAML frontmatter | All `agents/*.md` and `skills/ocat/SKILL.md` have valid YAML between `---` delimiters |
| JSON validity | `scaffold/opencode.json.snippet` is valid JSON |
| JSON validity | `scaffold/ocat.json.snippet` is valid JSON |
| Required fields | Each agent has `mode`, `model`, `permission`; Architect/Reviewer have `steps` |
| Agent count | Exactly 5 files matching `agents/ocat-*.md` |
| Naming convention | All agent filenames start with `ocat-` |
| Skill frontmatter | `SKILL.md` has `name: ocat` |
| Agent roles table | Names in `SKILL.md` agent table match actual filenames |
| Snippet keys | `ocat.json.snippet` contains `active_agents` |
| No hardcoded paths | `install.sh` doesn't contain `/home/` paths (portability guard) |

**Dependencies:** Python 3 with `yaml` (PyYAML), `json` (stdlib).

---

## 4. Tier 2: Functional Testing

**Goal:** Verify `install.sh` behavior in isolated, mocked environments.

**Implementation:** `tests/test_install.bats`

**Framework:** [bats](https://github.com/bats-core/bats-core) — Bash Automated Testing System.

| Test Case | Description |
|---|---|
| `global: installs agents and skill` | `--global` copies all agent `.md` files and `SKILL.md` to `~/.config/opencode/` |
| `global: creates target directories` | Installer creates `agents/` and `skills/ocat/` dirs if absent |
| `global: installs exactly 5 agent files` | 5 `ocat-*.md` files land in destination |
| `global: uninstall removes all ocat files` | `--uninstall --global` removes agents and skill directory |
| `global: uninstall is idempotent` | Running uninstall twice doesn't error |
| `project: installs agents and skill` | `--project <dir>` copies files to `<dir>/.opencode/` |
| `project: scaffolds opencode.json` | Creates `opencode.json` from snippet when absent |
| `project: skips scaffold when exists` | Doesn't overwrite existing `opencode.json` |
| `project: errors on missing project dir` | Fails with non-zero exit for non-existent directory |
| `error: missing agents source` | Fails when `agents/` directory is missing |
| `error: missing skill source` | Fails when `skills/ocat/SKILL.md` is missing |
| `idempotent: double install` | Running install twice produces same result |

**Dependencies:** bats-core (`npm install -g bats` or system package manager).

---

## 5. Tier 3: Integration / POC Testing

**Goal:** Validate that the multi-agent workflow functions correctly in a real OpenCode runtime.

**Cost:** High (LLM API calls, human time). Run pre-release, not per-commit.

| POC Test | Scope | Success Criteria |
|---|---|---|
| **POC: Phase 0-1** | Trivial project (e.g., "CLI hello-world in Python"), Requirements + Design with Architect + Reviewer | Design document produced, Reviews pass, Master board updated |
| **POC: Full pipeline** | Same project, all phases (0-3) through Quality Gate | Working code + tests + approved final review |
| **Review cycle exercise** | Task that deliberately needs revision → verify re-delegation loop | NEEDS_REVISION → Developer fixes → APPROVED (or escalation at iteration 3) |
| **Active agents filtering** | `active_agents: ["architect", "developer"]` — orchestrator doesn't invoke reviewer/explorer | Non-active agents never receive task delegation |
| **MAX_REVIEW_ITERATIONS** | Task stuck at NEEDS_REVISION after 3 iterations | Orchestrator escalates to user with summary |

**Note:** These tests depend on OpenCode runtime availability and LLM provider access. They should be run manually in a controlled environment.

---

## 6. Tier 4: Semantic / Prompt Quality

**Goal:** Manual review of agent prompt quality — coverage, clarity, consistency.

**When:** On initial creation and after major prompt changes.

| Aspect | Check |
|---|---|
| Orchestrator workflow | Phases 0-3 correctly described; escalation triggers complete |
| Reviewer criteria | All 4 stage types covered (Requirements, Design, Implementation, Tests) |
| Developer constraints | Test coverage required; architecture-change escalation |
| Explorer scope | Steps limit tight; read-only enforced |
| Board templates | Master board + task board templates complete and usable |
| Role consistency | Skill table matches agent file definitions |

---

## 7. CI Integration (planned)

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make validate

  install-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install -g bats
      - run: make install-test
```

---

## 8. Running Tests Locally

```bash
# Tier 1: static validation (0 dependencies beyond Python)
make validate

# Tier 2: installer functional tests (requires bats)
make install-test

# Run all
make test
```
