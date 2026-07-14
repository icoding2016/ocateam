# OCATeam — 多智能体项目交付框架

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
git clone https://github.com/YOUR_ORG/ocateam.git
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
| 3: 最终交付 | 开发者 + 审查者 | 集成测试 + 最终审查结论 | 🔒 强制审批 |

### 每阶段活动

Phase 2 的每个交付阶段包含两个嵌套循环：

1. **开发者自主循环**：`实现 → 测试 → 修复` — 协调者不干预
2. **审查者循环**（最多 N 轮）：`审查 → [驳回] 修复 → 测试 → 重新审查` — N 通过 `.ocat.json` 配置

每阶段结束后：检查阶段门控（`.ocat.json.gates.delivery_stage_approval`）→ 人工审批或自动继续。

## 配置

OCATeam 使用两个配置文件：

| 文件 | 用途 |
|------|------|
| `.ocat.json` | OCATeam 工作流配置（门控、权限模式、审查限制） |
| `opencode.json` | 标准 OpenCode 配置（模型覆盖、agent 权限） |

### `.ocat.json` — 工作流控制

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

### 门控值语义

| 值 | 行为 |
|-------|----------|
| `"mandatory"` | 不可关闭。协调者必须调用 `confirm_with_user()`。 |
| `true` | 默认启用，可设为 `false`。 |
| `false` | 默认禁用，可设为 `true`。 |

- Phase 0、1、3 的门控始终为强制（需求/设计/最终交付太关键，不可跳过）
- `delivery_stage_approval` 控制每阶段的人工审批（默认：需要）

### 权限模式

协调者有三级权限配置，通过 `.ocat.json` 的 `permission_mode` 控制：

| 模式 | 协调者权限 | 适用场景 |
|------|------------|----------|
| `strict` | `bash: ask`，`edit: ask` | 高安全环境 |
| `balanced` | 细粒度 bash 规则（grep/cat/find/ls/git/echo/cp/file 自动允许，其他需确认） | 正常开发（**默认**） |
| `auto` | `bash: allow`，`edit: allow` | 可信赖的快速工作流 |

切换权限模式有两种方式：

**方式一 — 自动（推荐）：**
```bash
# 安装时指定：
./install.sh --project ~/code/my-app --permission-mode auto

# 安装后切换：
./install.sh --project . --permission-mode strict
```
一条命令同时更新 `.ocat.json` 和 `opencode.json`，无需重装。

**方式二 — 手动：**
```bash
# 编辑 .ocat.json 修改 permission_mode:
#   "permission_mode": "auto"

# 然后编辑 opencode.json 添加对应覆盖：
#   { "agent": { "ocat-orchestrator": { "permission": { "bash": "allow", "edit": "allow" } } } }
```

**注意：** OpenCode 读取 `opencode.json` 中的权限覆盖（不直接读 `.ocat.json`）。安装器负责把 `.ocat.json` 的 `permission_mode` 翻译成 `opencode.json` 中的 agent 权限覆盖。`balanced` 模式使用 agent 内置默认配置，无需覆盖。

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

> **为什么有两个配置文件？** `opencode.json` 受 OpenCode schema 校验，会拒绝未知的 key。OCATeam 的配置放在独立的 `.ocat.json` 中，避免 schema 冲突。安装器通过 `opencode.json` 的 `agent.<name>.permission` 字段处理权限模式覆盖，该字段是 OpenCode 原生支持的。

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
├── tests/                   # 测试套件
│   ├── validate.sh          # Tier 1: 23 项静态校验
│   ├── test_install.bats    # Tier 2: 17 个安装脚本功能测试
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
make test            # 全部测试
```

POC 已验证端到端：在 `hello-cli` 测试项目上完成了全部 5 个阶段。详见 `tests/tier3_results.md`。

## 环境要求

- **OpenCode** v1.17+（支持多 agent）
- **Python 3**（用于校验脚本）
- **bats-core**（可选，Tier 2 测试需要）

## 许可证

MIT
