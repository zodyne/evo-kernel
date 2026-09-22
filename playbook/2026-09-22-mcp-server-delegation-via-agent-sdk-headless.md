---
id: mcp-server-delegation-via-agent-sdk-headless
type: playbook
status: validated
scope: global
domain: agent-ops
tags: [mcp, agent-sdk, delegation, headless, claude-code, prompt-cache]
triggers:
  - "主会话想把子任务无感派给第三方模型执行端，又不想用 shell / 轮询 / 子 agent"
  - "设计一个 MCP server 用 Agent SDK 起无头 Claude Code 当执行手脚"
  - "MCP 调用超过两分钟后主会话该怎么拿回结果"
  - "给执行端配模型时，希望它走网关而不是订阅额度"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:inbox/capture-2026-09-20-05-46-44-309-6prn
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [agentic-delegation-empty-response-must-fail-explicitly, mcp-stateful-tool-error-list-all-invalidation-causes]
---

# 无感派活给第三方执行端：MCP server 里用 Agent SDK `query()` 起无头 Claude Code

**主张**：把子任务「无感」派给第三方模型执行端的可行形态是 **MCP server**（`~/Dev/claude-executor-mcp`）：
内部用 Agent SDK `query()` 起无头 Claude Code，`options.env` **整体替换**为网关
`BASE_URL` + `API_KEY` + `DEFAULT_*_MODEL`（订阅不参与），`effort: max`，
`allowedTools` 白名单而非 `bypassPermissions`，`strictMcpConfig` + 空 `mcpServers` 防递归。
主会话侧 MCP 调用超 2 分钟会自动转后台任务、结束以通知送回（≥2.1.212）——
**不需要 shell、轮询或子 agent**。

## 为什么

三件事同时被满足：① 派活形态对主会话无感（就是一个工具调用）；
② 执行端用网关计费而不是订阅额度（env 整体替换是关键，靠继承会漏）；
③ 防递归（空 mcpServers + strictMcpConfig）。

## 证据（本会话实测）

- 玩具卡 43s / 12 轮；网关前缀缓存把 Claude Code 每轮 ~19K 系统提示开销吸收
  （`160K cache_read : 22.7K miss`）。
- 版本坑：`agent-sdk 0.3.278` peer 要 `zod ^4` + `mcp sdk ^1.29`；
  `Client.setNotificationHandler` 必须传 zod schema。

## 边界 / 反例

- 「2 分钟自动转后台 + 通知送回」依赖 Claude Code ≥ 2.1.212，更低版本要自己轮询。
- 缓存收益依赖网关支持前缀缓存；换网关/直连厂商时那 19K/轮的开销会实付。
