# Contributing to OCATeam

Thanks for your interest in contributing! OCATeam is an agent-definition framework — contributions range from improving agent prompts to adding tests to fixing the installer.

## Ways to Contribute

| Area | Examples |
|------|----------|
| **Agent prompts** | Improve orchestrator workflow clarity, add edge-case handling to reviewer |
| **Skill content** | Better board templates, clearer phase definitions, new coordination patterns |
| **Installer** | New install modes, better error handling, cross-platform fixes |
| **Tests** | More validation checks, additional bats test cases, new POC scenarios |
| **Documentation** | README improvements, design doc updates, translations |

## Setup

```bash
git clone https://github.com/YOUR_ORG/ateam.git
cd ateam

# Run validation after any change
make validate
```

## Agent File Conventions

Agent definition files (`agents/ateam-*.md`) follow this structure:

```markdown
---
description: <one-line purpose>
version: <semver>
mode: primary | subagent
model: <provider/model>
steps: <max steps>
permission:
  edit: allow | ask | deny
  bash: allow | ask | deny
  webfetch: allow | deny
---

<agent prompt in Markdown>
```

Rules:
- **YAML frontmatter must be valid** — colons in values must be quoted
- **`ateam-` prefix** is mandatory for all agent filenames
- **`steps:` cap** is required on all subagents
- **`mode:`** must be `primary` (only orchestrator) or `subagent` (all others)
- Agent prompts must reference board file output paths

## Testing

Before submitting a PR:

```bash
make test          # Runs all tests (validate + install-test)
```

If you don't have `bats` installed:

```bash
make validate      # Static validation only (always runs)
```

### Adding Tests

- **Tier 1** (`tests/validate.sh`): Add bash/python checks for new invariants
- **Tier 2** (`tests/test_install.bats`): Add `@test` cases for installer behavior changes
- **Tier 3** (POC): Run a full end-to-end project, document results in new `tests/tier3_*.md`

## Pull Request Checklist

- [ ] `make validate` passes (23/23 checks)
- [ ] If installer changed: `make install-test` passes (17/17 tests)
- [ ] If agent prompts changed: manually verify in OpenCode with a trivial project
- [ ] If `active_agents` or config changed: update both `ocat.json.snippet` and docs
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] Version bumped in `VERSION` and all frontmatter if a release is intended

## Commit Conventions

Use conventional commits:

```
feat: add auto-escalation on review timeout
fix: quote YAML description values with colons
docs: add bilingual README
test: add install idempotency check
chore: bump version to 0.1.1
```

## Release Process

1. Update `VERSION` file
2. Update `version:` in all 5 agent files + `SKILL.md`
3. Update `CHANGELOG.md` — move `[Unreleased]` to dated release section
4. Commit: `chore: release vX.Y.Z`
5. Tag: `git tag vX.Y.Z && git push --tags`

## Code of Conduct

Be respectful. This is a small project — we value clear communication and constructive feedback.
