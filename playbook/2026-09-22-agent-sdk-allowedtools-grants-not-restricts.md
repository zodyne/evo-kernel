---
id: agent-sdk-allowedtools-grants-not-restricts
type: playbook
status: validated
scope: global
domain: agent-ops
tags: [agent-sdk, allowedtools, permissions, tools, claude-code]
triggers:
  - "给 Agent SDK 会话配 allowedTools 想限制可用工具，发现限制没生效"
  - "想真正收窄无头 Claude Code 的工具基集"
  - "disallowedTools 的 Bash(pattern) 写法在任何 permissionMode 下都被拒"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:inbox/capture-2026-09-20-09-07-03-836-xwzi
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [mcp-server-delegation-via-agent-sdk-headless, pi-tools-allowlist-filters-extension-tools]
---

# Agent SDK 的 `allowedTools` 只是**自动放行**，不是可用工具上限

**主张**：Agent SDK 0.3.278 里 `allowedTools` 的语义是「这些不用问」，**不限制工具基集**；
要限制基集必须用 `options.tools`（`string[]`）。另两条：`disallowedTools` 的 `Bash(pattern)`
形式**在任何 `permissionMode` 下都拒**；`skills` 选项是开技能的唯一入口
（**不需要**把 `Skill` 加进 `allowedTools`）。

## 为什么

「放行」与「可用」是两个维度。把它们当成同一件事，会得到「我明明设了白名单，它却调了我没列的工具」
这种看似权限泄漏、实为语义误解的现象 —— 与 pi 侧 `pi-tools-allowlist-filters-extension-tools`
是同类混淆，但两个 harness 的具体字段不同，不要互推。

## 证据

- 来源：`sdk.d.ts` 注释，2026-09-20 在 `claude-executor-mcp` 设计时核实。

## 边界 / 反例

- 版本相关（0.3.278）；升级 SDK 后先复核 `sdk.d.ts` 再沿用本条。
- `skills` 是唯一入口这条也只在该版本核实过。
