# Security Policy

## Reporting a Vulnerability

OCATeam is a framework that defines agent prompts and installation scripts — it does not run network services, handle user data, or execute untrusted code at runtime. However, if you discover a security concern (e.g., an unsafe pattern in the installer, a prompt injection vector, or a dependency issue), we encourage you to report it.

Please **do not** open a public issue. Instead, report vulnerabilities via email to the maintainers. Include:

- A clear description of the issue
- Steps to reproduce (if applicable)
- Suggested fix (if available)

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.3.x   | ✅ Active development |
| < 0.3.0 | ❌ No longer supported |

## Scope

The security policy covers:

- `install.sh` and `install.ps1` — installer scripts
- Agent definition files (`agents/ocat-*.md`) — prompt content and permission configuration
- The `ocat` skill (`skills/ocat/SKILL.md`) — workflow definitions
- Scaffold templates (`scaffold/*.snippet`)
- Test scripts and CI configuration

This policy does **not** cover:

- Third-party AI model providers invoked through OpenCode at runtime
- OpenCode itself (report those to the [OpenCode project](https://github.com/opencode-ai/opencode))

## Acknowledgments

We appreciate responsible disclosure and will acknowledge reporters in release notes (with permission).
