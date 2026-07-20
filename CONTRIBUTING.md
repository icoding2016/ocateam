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
git clone https://github.com/YOUR_ORG/ocateam.git
cd ocateam

# Run validation after any change
make validate
```

## Agent File Conventions

Agent definition files (`agents/ocat-*.md`) follow this structure:

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
- **`ocat-` prefix** is mandatory for all agent filenames
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

- [ ] `make validate` passes (all checks)
- [ ] If installer changed: `make install-test` passes (all tests)
- [ ] If adding new features: add corresponding tests
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

OCATeam uses a lightweight release process suitable for a v0.x project:

### 1. Prepare the Release

- Update `VERSION` file with the new version number
- Update `version:` field in all 5 agent files (`agents/ocat-*.md`) and `skills/ocat/SKILL.md`
- Move `[Unreleased]` entries in `CHANGELOG.md` to a new dated release section:
  ```markdown
  ## [X.Y.Z] - YYYY-MM-DD
  
  ### Added
  - ...
  
  ### Changed
  - ...
  
  ### Fixed
  - ...
  ```
- Commit: `chore: release vX.Y.Z`

### 2. Tag and Push

```bash
git tag vX.Y.Z
git push origin main --tags
```

### 3. Create GitHub Release

1. Go to the [Releases page](https://github.com/icoding2016/ocateam/releases)
2. Click **Draft a new release**
3. Choose the tag `vX.Y.Z` created above
4. Title: `vX.Y.Z`
5. Copy the relevant section from `CHANGELOG.md` as the release description
6. Publish

### 4. Post-Release

- Bump `VERSION` and all `version:` fields to the next development version
- Add a new `[Unreleased]` section to `CHANGELOG.md`
- Commit: `chore: bump version to X.Y.Z-dev`

### 5. Release Cadence

At this stage (pre-1.0), releases are on-demand when a coherent set of changes is ready. There is no fixed schedule. All releases use [Semantic Versioning](https://semver.org/):
- **Patch** (0.3.X): bug fixes, minor corrections
- **Minor** (0.X.0): new features, workflow improvements
- **Major** (1.0.0): stable public API

## Code of Conduct

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
