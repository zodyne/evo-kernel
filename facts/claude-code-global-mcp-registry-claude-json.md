---
id: claude-code-global-mcp-registry-claude-json
type: fact
status: candidate
scope: global
domain: harness-config
tags: [claude-code, mcp, config, backup]
triggers:
  - "给 Claude Code 全局增删/修改 MCP server"
  - "Claude Code 的全局 MCP server 注册表在哪个文件"
  - "脚本化注册 MCP server 到 Claude Code"
  - "要直接编辑 ~/.claude.json 之前（失败信号：改坏 JSON 整个配置报废）"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fae52-a170-7aba-bfe6-f7e1676655d0
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [pi-mcp-adapter-global-config-path, backup-untracked-file-before-edit]
---

**主张**：Claude Code 的全局 MCP server 注册表是 `~/.claude.json` 顶层的 `mcpServers` 对象；用 python json 读写直接改它即可完成注册。改前先做带时间戳的整文件备份（`cp ~/.claude.json ~/.claude.json.bak.$(date +%Y%m%d%H%M%S)`），不用 sed 手改——这个文件是全量配置，改坏 JSON 影响面极大。

**证据**：会话中 `cp` 时间戳备份后用 python3 `json.load`/`json.dump` 往顶层 `mcpServers` 写入 pal 条目，输出确认 `pal registered. mcpServers now: ['gitnexus', 'searxng', 'multi-model', 'pal']`，随后冒烟通过。

**边界**：这是 Claude Code 的注册位置；pi 的全局 MCP 配置在别处（见 `pi-mcp-adapter-global-config-path`），改了 `~/.claude.json` 对 pi 不生效。
