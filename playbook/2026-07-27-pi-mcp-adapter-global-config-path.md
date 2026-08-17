---
id: pi-mcp-adapter-global-config-path
type: lesson
status: archived
scope: global
domain: harness-config
tags: [pi, mcp, config, harness]
triggers:
  - "在 pi（pi-coding-agent）里增删全局 MCP server"
  - "pi 的全局 MCP 配置文件在哪"
  - "改了 ~/.claude.json 后某个 MCP server 仍在加载"
  - "pi-mcp-adapter 从哪个文件读 MCP server 列表"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019f8a68-b1c6-7794-80e8-e6afa0c28aa1
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
pi 的 `pi-mcp-adapter` 把**全局** MCP server 列表读自 `~/.config/mcp/mcp.json`（`GENERIC_GLOBAL_CONFIG_PATH = join(homedir(), ".config", "mcp", "mcp.json")`），而非 `~/.claude.json` 或 `~/.pi/agent/mcp.json`。

**做法**：增删 server（如移除 gbrain）时三处要对齐——`~/.claude.json`（Claude Code 项目级）、`~/.claude/.mcp.json`（Claude Code 用户级）、`~/.config/mcp/mcp.json`（pi 全局）；只改一处会导致 pi 侧仍加载旧 server。
**证据**：gbrain cutover 会话中 `grep config.ts` 直接命中 `GENERIC_GLOBAL_CONFIG_PATH = join(homedir(), ".config", "mcp", "mcp.json")`，并据此备份+编辑了 `~/.config/mcp/mcp.json` 才彻底移除 gbrain。
**边界**：不同 pi-mcp-adapter 版本路径可能变，以 `grep -rh GENERIC_GLOBAL_CONFIG_PATH node_modules/pi-mcp-adapter/config.ts` 现场核实为准。
