---
id: disable-nonessential-traffic-stops-reading-agents-md
type: playbook
status: validated
scope: global
domain: claude-code
tags: [claude-code, env-vars, agents-md, feature-flags, headless]
triggers:
  - "无头执行端设了 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1，仓里 AGENTS.md 的纪律没生效"
  - "同一个仓库在本地读得到 AGENTS.md、在无头执行端却读不到"
  - "只想关遥测，结果把项目指令文件也一起关掉了"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:inbox/capture-2026-09-20-09-50-30-370-ofut
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [claude-code-global-mcp-registry-claude-json]
---

# `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` 的副作用：Claude Code 不再读 AGENTS.md

**主张**：`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`（或 `DISABLE_TELEMETRY` / `DISABLE_GROWTHBOOK`）
会关掉 feature-flag 拉取，**副作用之一是 Claude Code 不再把 `AGENTS.md` 当项目指令读**
（只读 `CLAUDE.md`）。无头执行端设了这些变量时，仓里要放一个 `CLAUDE.md` 且其中含一行
`@AGENTS.md`，才能保住 `AGENTS.md` 里的纪律。

## 为什么

`AGENTS.md` 的支持是**由 feature flag 门控**的：关掉 flag 拉取 = 该能力回落到默认关闭。
这不是「配置写错」，所以查配置文件查不出来；症状是「同一份仓库，本地生效、无头不生效」。

## 证据

- 来源：官方文档 `docs/en/env-vars`「Features that need feature-flag fetching」，2026-09-20 核实。

## 边界 / 反例

- 是**文档核实**结论，未在本机做开/关对照实验 → 首次遇到时按「加一行 `@AGENTS.md`」验证即可证伪。
- 只覆盖 `AGENTS.md` 这一条已知回落；同族还有哪些能力被 flag 门控，文档那一节才是权威清单。
