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
verified_by: human
source: capture:inbox/capture-2026-09-20-05-46-44-309-6prn
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [agentic-delegation-empty-response-must-fail-explicitly, mcp-stateful-tool-error-list-all-invalidation-causes]
---

# 无感派活给第三方执行端：MCP server 里用 Agent SDK `query()` 起无头 Claude Code

**主张**：本次会话落地的一条派活形态是 **MCP server**（`~/Dev/claude-executor-mcp`）：
内部用 Agent SDK `query()` 起无头 Claude Code，`options.env` **整体替换**为网关
`BASE_URL` + `API_KEY` + `DEFAULT_*_MODEL`（订阅不参与），`effort: max`，
`allowedTools` 白名单而非 `bypassPermissions`，`strictMcpConfig` + 空 `mcpServers`（capture 记的用途是**防递归**）。

> ⚠ 本条 capture 用的「白名单」是它的字面措辞。**`allowedTools` 本身只负责自动放行、不限制可用工具基集**
> ——该说法见同批的 `agent-sdk-allowedtools-grants-not-restricts`（另一条 capture）。两者不矛盾但极易误读：
> 要**限制**执行端的工具边界，得用 `options.tools`，不是 `allowedTools`。
主会话侧 MCP 调用超 2 分钟会自动转后台任务、结束以通知送回（≥2.1.212）。

## 证据

- 玩具卡 43s / 12 轮；网关前缀缓存把 Claude Code 每轮 ~19K 系统提示开销吸收
  （`160K cache_read : 22.7K miss`）。
- 版本坑：`agent-sdk 0.3.278` peer 要 `zod ^4` + `mcp sdk ^1.29`；
  `Client.setNotificationHandler` 必须传 zod schema。

证据等级：`verified_by: human` —— 来源是会话内的 prose 摘要（`capture:…`），无命令转录。
**未经本机复核** —— `command` 档要求命令级可复现证据，本条没有。

## 边界 / 反例

- 这是**一条落地过的形态**，不是「正解」或唯一解——本次没有与其它派活形态做过对比。
- `options.env` 整体替换与「走网关而非订阅」是**同一次记录里的写法**。capture 未验证
  「只继承不替换会怎样」——本条不补那半句因果。
- 缓存收益依赖网关支持前缀缓存；该前提不成立时每轮那 ~19K 会实付——这是**由前提推出的**，
  capture 未测过换网关的情形。
- 2 分钟门限对应 Claude Code ≥ 2.1.212。capture 只给了这个门限，**没交代低版本怎么办**；
  本条也不猜（要自己轮询还是别的）。
