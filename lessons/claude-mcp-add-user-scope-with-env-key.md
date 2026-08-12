---
id: claude-mcp-add-user-scope-with-env-key
type: lesson
status: candidate
scope: global
domain: harness-config
tags: [claude-code, mcp, scope, api-key, config, claude-mcp-add]
triggers:
  - "用 claude mcp add 给 Claude Code 注册一个要全局可用的 MCP server"
  - "MCP server 只在某个项目目录下能用，换个目录就不见（失败信号）"
  - "注册 MCP server 时要传 API key，不想让它进项目 .mcp.json / git"
  - "project scope 的 MCP server 每个项目都要审批一次"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:9df36dfc-790a-4022-b8d8-620e0ced67ea
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [claude-code-global-mcp-registry-claude-json, pi-mcp-adapter-global-config-path]
---

**主张**：给 Claude Code 注册要全局可用的 stdio MCP server，用 `claude mcp add --transport stdio <name> --scope user -e KEY=value -- <cmd> [args...]`。`--scope project` 会写进**项目** `.mcp.json`（有进 git 风险、换目录不可用、需逐项目审批）；`--scope user` 任意目录下的会话都能连；`-e KEY=value` 把密钥注入 server 进程环境、落在用户级配置（`~/.claude.json`）而非项目文件。

**证据（切片硬证据）**：
- `$ claude mcp add --transport stdio multi-model --scope project -- ...` → 成功，但配置落在 `~/graph-lab/.mcp.json`。
- `$ claude mcp remove multi-model -s project` → `Removed ... File modified: /Users/zodyne/graph-lab/.mcp.json`，之后 `cat .mcp.json` → `{"mcpServers": {}}`。
- `$ claude mcp add --transport stdio multi-model --scope user -e MOONSHOT_API_KEY=sk-... -- <python> <script>` → `Added stdio MCP server multi-model ...`；`claude mcp list` 能看到该 server。
- 末条 assistant 汇报（人判断部分）：user scope 后「全局任意目录可用、✔ Connected、不再需要逐项目审批，密钥存 ~/.claude.json 不走 git」——「逐项目审批」这一行为差异切片中无直接命令输出，如实标注。

**边界**：与 `claude-code-global-mcp-registry-claude-json`（直接编辑 ~/.claude.json 注册）互补——本条是官方 CLI 路径，优先用 CLI 而非手改 JSON。pi 侧不认这套，pi 的全局 MCP 在 `~/.config/mcp/mcp.json`（见 `pi-mcp-adapter-global-config-path`），双 harness 要各自注册。
