---
id: mcp-idle-window-reset-only-by-tool-response-or-progress
type: playbook
status: validated
scope: global
domain: claude-code
tags: [mcp, idle-timeout, progress, keepalive, long-running-tool]
triggers:
  - "长时 MCP 工具跑到一半被客户端掐断连接（stdio 空闲超时）"
  - "想给长任务 MCP 工具做保活，不确定发什么通知才算数"
  - "发了 logging 通知但空闲窗没有被重置"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:inbox/capture-2026-09-20-09-07-03-800-2v9c
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [mcp-server-delegation-via-agent-sdk-headless, mcp-stateful-tool-error-list-all-invalidation-causes]
---

# Claude Code 的 MCP 空闲窗只被「工具响应」或 `notifications/progress` 重置，logging 通知不算

**主张**：Claude Code 对 stdio MCP server 的 30 分钟空闲窗口，**只被工具响应或
`notifications/progress` 重置**；`sendLoggingMessage` 发的 logging 通知**不算**。
长时 MCP 工具保活必须发 **progress**（需要客户端的 `progressToken`）。

## 为什么

把「发通知」当成通用的保活手段会踩空：协议里存在多种通知，但只有进度通知被实现为活跃信号。
兜底开关是 `CLAUDE_CODE_MCP_TOOL_IDLE_TIMEOUT`。

## 证据

- 来源：官方文档 `docs/en/mcp` 原文，2026-09-20 在写 `claude-executor-mcp` 详细设计时核实。

## 边界 / 反例

- 本条是**文档核实**结论，不是本机端到端复现 ⇒ `verified_by: human`
  （2026-09-22 复核时由 `command` 降级：权重 0.8 → 0.6。证据是官方文档原文 + 设计落地，
  没有跑出可复现的观测；首次遇到掐断时应先用一次长时工具实测确认版本行为，
  复现通过后可再升回 `command`）。
- 30 分钟是文档值，随版本可调；以 `CLAUDE_CODE_MCP_TOOL_IDLE_TIMEOUT` 的实际生效值为准。
