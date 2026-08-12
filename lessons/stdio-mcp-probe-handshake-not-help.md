---
id: stdio-mcp-probe-handshake-not-help
type: lesson
status: candidate
scope: global
domain: mcp-debug
tags: [mcp, stdio, debugging, npx]
triggers:
  - "排查 stdio MCP server 连不上"
  - "MCP server --help 挂住"
  - "npx -y 启动 MCP 无输出 0 CPU"
  - "MCP 握手超时"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:b6cf7fd7
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
---

**主张**：排查 stdio MCP server 时两条反直觉事实：① 对 server 直接跑 `--help` 挂住是**正常**的（它在等 JSON-RPC，不是卡死），这个探针不成立，要改用真正的 initialize 握手探测并计时；② `npx -y <pkg>` 形式的 server 在 registry 不可达时会无限期挂住（0 CPU 干等），是「假死」高发形态。

**为什么**：会话中两个 MCP server（`npx -y luma-mcp` 与本地 python searxng）分别踩到这两种形态；改用握手探测后两个都 1–2 秒成功，直接排除了 MCP 层嫌疑。

**边界**：握手探测要看 server 吐出的字节数/内容判断是否活着；npx 挂住时先单独计时 `npx -y <pkg> --version` 验证 registry 可达性，或改本地安装绕开。

**证据**：2026-07-29 evo-kernel 会话排查 pi agent 协同失败，MCP 层用此方法快速排除，最终根因在别处（API 延迟）。
