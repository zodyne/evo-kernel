---
id: mcp-server-add-remove-align-three-registries
type: lesson
status: validated
scope: global
domain: mcp
tags: [mcp, claude-code, pi, config, decommission]
triggers:
  - "给 Claude Code 或 pi 增删 MCP server"
  - "改了 ~/.claude.json 后某个 MCP server 仍被加载或没生效"
  - "看到 ~/.claude/.mcp.json 是 {} 就以为本机没有 MCP"
  - "排查本机有哪些 MCP server、各自注册在哪个文件"
  - "退役一个本地组件，它曾注册过 MCP server"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09e0b-11c3-7129-be3e-24826f4f7cc9
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [claude-code-global-mcp-registry-claude-json, pi-mcp-adapter-global-config-path]
---

增删本机 MCP server 必须三处同时对齐，且 `~/.claude/.mcp.json` 为空不代表 Claude Code 无 MCP——真正的全局注册表在 `~/.claude.json` 顶层 `mcpServers`。

为什么：本机有 3 个独立的 MCP 注册点——`~/.claude.json`（Claude Code 项目级/全局，顶层 `mcpServers`）、`~/.claude/.mcp.json`（Claude 用户级，本机为 `{}`）、`~/.config/mcp/mcp.json`（pi 全局，经 pi-mcp-adapter 读取，未装则休眠）。它们互不同步：只改一处，另一侧仍加载旧 server，或误判「无 MCP」。实测本机 `~/.claude/.mcp.json` 为 `{"mcpServers": {}}`，但 `~/.claude.json` 顶层 `mcpServers` 里有 vision-bridge/searxng/evo-kernel 三条——「某文件为空 ⇒ 无 MCP」这条推理本身就是错的。

反例/边界：加 server 时若只写 `~/.claude/.mcp.json`（用户级空文件），Claude 侧根本不读它；删 server 时若只清 `~/.claude.json`，pi 的 `~/.config/mcp/mcp.json` 仍会加载旧 server（若 adapter 装上）。三处不是同域重复，是不同 harness 的各自入口。

证据：`cat ~/.claude/.mcp.json` → `{"mcpServers": {}}`；`~/.claude.json` 顶层 `mcpServers` 含 vision-bridge 等 3 条；`~/.config/mcp/mcp.json` 独立存 vision+searxng；会话随后从 `~/.claude.json` 移除了死 MCP 条目并更新 AGENTS.md 三处对齐说明。
