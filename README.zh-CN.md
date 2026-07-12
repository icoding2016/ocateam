# OCATeam — 多智能体项目交付框架

> 🚀 端到端的智能体软件交付：需求分析 → 设计 → 实现 → 测试 → 质量门。
> 基于 OpenCode 的多 agent 运行时。一条命令安装，每个项目零配置。

[English](README.md)

---

## 什么是 OCATeam？

OCATeam 是一个可复用的**多智能体框架**，通过 OpenCode 的 agent 系统实现端到端软件项目交付。它定义了：

- **5 个专业 agent**：协调者（Orchestrator）、架构师（Architect）、开发者（Developer）、审查者（Reviewer）、探索者（Explorer）
- **5 个工作流阶段**：需求分析 → 设计 → 实现 → 测试 → 质量门
- **基于文档的协调**：所有 agent 通过 `boards/` 目录下的文档进行沟通
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

| 阶段 | 负责人 | 产出物 |
|------|--------|--------|
| 0: 需求分析 | 协调者 | 明确的需求文档（主面板） |
| 1: 设计 | 架构师 → 审查者 | 设计文档，已审查通过 |
| 2: 实现 | 开发者 → 审查者 | 代码 + 测试，审查循环把关 |
| 3: 测试 | 开发者 → 审查者 | 测试结果 + 修复，覆盖率验证 |
| 4: 质量门 | 审查者 | 对照原始需求的最终裁决 |

每个实现任务都经过**实现/改进 → 审查**循环（最多 3 轮迭代后升级给用户）。

## 配置

### Agent 激活 (`ocat.json`)

按项目安装时会自动创建 `ocat.json` 来控制哪些 subagent 处于激活状态：

```json
{
  "active_agents": ["architect", "developer", "reviewer", "explorer"]
}
```

- 移除条目可停用特定项目的 agent
- 如果 `ocat.json` 不存在（全局安装），所有 agent 默认激活

### 模型覆盖 (`opencode.json`)

在标准 OpenCode 配置中覆盖 agent 模型：

```json
{
  "agent": {
    "ocat-developer": { "model": "openai/gpt-5" }
  }
}
```

> **为什么有两个配置文件？** `opencode.json` 受 OpenCode schema 校验，会拒绝未知的 key。OCATeam 的配置放在独立的 `ocat.json` 中，避免 schema 冲突。

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
