# OCATeam — 多智能体项目交付框架

[![Test](https://github.com/icoding2016/ocateam/actions/workflows/test.yml/badge.svg)](https://github.com/icoding2016/ocateam/actions/workflows/test.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.3.0-blue)]()

> 🚀 端到端的智能体软件交付：需求分析 → 设计 → 实现 → 测试 → 质量门。
> 基于 OpenCode 的多 agent 运行时。一条命令安装，每个项目零配置。

[English](README.md)

---

## 什么是 OCATeam？

OCATeam 是一个可复用的**多智能体框架**，通过 OpenCode 的 agent 系统实现端到端软件项目交付。它定义了：

- **5 个专业 agent**：协调者（Orchestrator）、架构师（Architect）、开发者（Developer）、审查者（Reviewer）、探索者（Explorer）
- **5 个工作流阶段**：需求分析 → 设计 → 实现 → 测试 → 质量门
- **基于文档的协调**：所有 agent 通过 `.boards/` 目录下的文档进行沟通
- **每阶段质量把关**：实现/改进 → 审查循环，自动升级机制

**核心理念：** OpenCode 支持 primary + subagent 架构，但不内置编排逻辑。OCATeam 将编排逻辑编码到 agent prompts 和工作流 Skill 中——无需外部包装脚本。

## 快速开始

### 1. 安装（一次性）

```bash
git clone https://github.com/icoding2016/ocateam.git
cd ocateam

# 全局安装：所有项目中均可使用
./install.sh --global

# 或：按项目安装（团队共享，版本控制）
./install.sh --project ~/code/my-app
```

### 2. 使用

```bash
# 在 OpenCode 中打开项目
opencode my-project/

# 按 Tab → 切换到 "ocat-orchestrator"
# 输入："Start a new project: 构建一个 CLI 工具..."
```

协调者会自动加载工作流、规划阶段、委派给专家 agent，并在 OpenCode 内完成质量把关。

## 架构

```
用户 → 协调者（Orchestrator，primary agent）
         ├── ocat-architect  — 系统设计，不写代码
         ├── ocat-developer  — 实现 + 测试
         ├── ocat-reviewer   — 质量把关，只读
         └── ocat-explorer   — 调研 + 检查
```

## 工作流阶段

OCATeam 将交付组织为多个阶段，每个阶段后设有**强制或可配置的人工审批门**：

| 阶段 | 负责人 | 产出物 | 门控 |
|------|--------|--------|------|
| 0: 需求面试 | 协调者 | 需求文档 (`.boards/.../requirements.md`) | 🔒 强制审批 |
| 1: 系统设计 + 交付计划 | 架构师 → 审查者 + 协调者 | 设计文档 + 多阶段交付计划 | 🔒 强制审批 |
| 2: 迭代交付（N 个阶段） | 开发者 → 审查者（每阶段） | 每个阶段：实现代码 + 测试 + 审查结论 | 🔓 可配置（默认需审批）|
| 3: 最终交付与质量门 | 开发者 + 审查者 | 集成测试 + 最终审查（4 维度） + 审查结论 | 🔒 强制审批 |

### 每阶段活动

Phase 2 的每个交付阶段包含两个嵌套循环：

1. **开发者自主循环**：`实现 → 测试 → 修复` — 协调者不干预
2. **审查者循环**（最多 N 轮）：`审查 → [驳回] 修复 → 测试 → 重新审查` — N 通过 `.ocat.json` 配置

每阶段结束后：检查阶段门控（`.ocat.json.gates.delivery_stage_approval`）→ 人工审批或自动继续。

## 配置

OCATeam 使用两个配置文件：

| 文件 | 用途 |
|------|------|
| `.ocat.json` | OCATeam 工作流配置（门控、激活的 agent、审查限制） |
| `opencode.json` | 标准 OpenCode 配置（模型覆盖、agent 权限） |

### `.ocat.json` — 工作流控制

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

### 门控值语义

| 值 | 行为 |
|-------|----------|
| `"mandatory"` | 不可关闭。协调者必须调用 `confirm_with_user()`。 |
| `true` | 默认启用，可设为 `false`。 |
| `false` | 默认禁用，可设为 `true`。 |

- Phase 0、1、3 的门控始终为强制（需求/设计/最终交付太关键，不可跳过）
- `delivery_stage_approval` 控制每阶段的人工审批（默认：需要）

### 自动批准权限

协调者 agent 文件使用 `bash: ask` — 所有 bash 命令都需要确认。

如果你希望跳过确认提示，可以使用 OpenCode 内置的自动批准功能：

| 方式 | 操作 |
|---|---|
| **CLI 启动** | `opencode --auto` 或 `opencode run --auto "..."` |
| **TUI 运行时** | `ctrl+p` → 命令面板 → 搜索 "auto-approve" → 开启 |

自动模式会批准所有 `ask` 请求，但显式的 `deny` 规则仍然生效。切换仅对当前会话有效，重启后不保留。

> **注意：** `opencode.json` 中的 agent 权限无法覆盖 agent 文件中的权限。所有协调者权限均在 `agents/ocat-orchestrator.md` 中直接设置。详见 `doc/design.md §11.10`。

### 审查上限

```json
{
  "review": {
    "max_iterations": 3
  }
}
```

控制每个阶段允许的审查→修复循环上限。默认：3 轮。超过后升级给用户处理。

### Agent 激活

```json
{
  "active_agents": ["architect", "developer", "reviewer", "explorer"]
}
```

- 移除条目可停用特定项目的 agent
- 如果 `.ocat.json` 不存在（全局安装），所有 agent 默认激活

### 模型覆盖 (`opencode.json`)

在标准 OpenCode 配置中覆盖 agent 模型：

```json
{
  "agent": {
    "ocat-developer": { "model": "openai/gpt-5" }
  }
}
```

> **为什么有两个配置文件？** `opencode.json` 受 OpenCode schema 校验，会拒绝未知的 key。OCATeam 工作流配置（门控、激活的 agent、审查限制）放在独立的 `.ocat.json` 中，避免 schema 冲突；模型覆盖使用标准 OpenCode 配置。

## 项目结构

```
ocat/
├── agents/                  # Agent 角色定义（YAML frontmatter + Markdown）
│   ├── ocat-orchestrator.md
│   ├── ocat-architect.md
│   ├── ocat-developer.md
│   ├── ocat-reviewer.md
│   └── ocat-explorer.md
├── skills/ocat/SKILL.md    # 工作流 Skill（阶段定义、模板、策略）
├── scaffold/                # 按项目安装的模板文件
│   ├── opencode.json.snippet
│   └── ocat.json.snippet
├── install.sh               # 一键安装脚本（支持全局/按项目）
├── install.ps1              # PowerShell 安装脚本 (Windows)
├── scripts/                 # 工具脚本
│   ├── migrate-v0.2.sh      # v0.1.x → v0.2.x 目录迁移
│   └── view-log.sh          # 执行日志查看器 (NDJSON)
├── tests/                   # 测试套件
│   ├── validate.sh          # Tier 1: 32 项静态校验
│   ├── test_install.bats    # Tier 2: 17 个安装脚本功能测试
│   ├── test_install.ps1     # Tier 2: 21 个 Pester 安装脚本测试
│   └── tier3_results.md     # Tier 3: POC 集成测试结果
├── Makefile                 # make validate, make test
└── doc/                     # 设计文档
    ├── prj_goal.md
    ├── design.md
    └── test_plan.md
```

## 测试

```bash
make validate        # Tier 1: 静态校验（23 项检查，<1 秒）
make install-test    # Tier 2: 安装脚本功能测试（需要 bats）
make test            # 全部测试 (validate + install-test)
```

POC 已验证端到端：在 `hello-cli` 测试项目上完成了全部 5 个阶段。详见 `tests/tier3_results.md`。

## 环境要求

- **OpenCode** v1.17+（支持多 agent）
- **Python 3**（用于校验脚本）
- **bats-core**（可选，Tier 2 测试需要）

## 许可证

Apache 2.0
