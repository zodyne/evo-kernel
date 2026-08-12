---
id: claude-code-local-plugin-marketplace-add
type: bullet
status: validated
scope: global
domain: claude-code
tags:
- claude-code
- plugin
- marketplace
- settings
- experimental-flag
triggers:
- 本地部署/测试一个 Claude Code 插件
- claude plugin marketplace add 指向本地目录
- 插件安装名与 quickstart 文档写的市场名对不上
- 想持久化 CLAUDE_CODE_EXPERIMENTAL_* 实验 flag
created: 2026-08-01
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: capture:capture-2026-08-01-15-39-57-659-eki8
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related:
- macos-no-timeout-command
---
Claude Code 本地插件部署可行：`claude plugin marketplace add <本地目录>`，要求仓库含 `.claude-plugin/marketplace.json` 且 plugin source 为 `./`。

**坑**：安装名是 `<plugin>@<marketplace.json 的 name 字段>`，与 quickstart 写的 GitHub 市场名可能不同——harness 案例本地是 `harness@harness-marketplace` 而非 `harness@harness`，照文档名引用会找不到插件。

**实验 flag 持久化**：`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 等写进 `~/.claude/settings.json` 的 `env` 块比写 shell rc 更可靠——覆盖所有 claude 会话，不依赖 shell 启动方式。

**边界**：macOS 无 `timeout` 命令（需 `gtimeout` 或用工具自带超时），插件/脚本里别假设它存在。
