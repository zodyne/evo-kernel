---
id: pal-chat-requires-working-directory-absolute-path
type: fact
status: candidate
scope: global
domain: mcp
tags: [pal-mcp, api-contract, required-parameter]
triggers:
  - "调用 PAL MCP 的 chat/clink 等工具"
  - "PAL 工具返回 Input validation error（失败信号）"
  - "'working_directory_absolute_path' is a required property（失败信号）"
  - "给 PAL MCP 写调用脚本或 JSON-RPC 请求体"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fae52-a170-7aba-bfe6-f7e1676655d0
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: []
---

**主张**：PAL MCP server 的 chat 工具（及同类工具）强制要求 `working_directory_absolute_path` 参数；不传直接返回 input validation error，不是可省略的可选项。

**证据**：会话中手动 JSON-RPC `tools/call` 调 chat，首次返回 `Input validation error: 'working_directory_absolute_path' is a required property`；补上该参数后同一条调用成功返回 `{"status":"continuation_available","content":"PAL-GLM-OK..."}`。

**边界**：这是 PAL 工具 schema 的硬约束，不是 GLM/custom provider 特有的行为；写调用方时把它当必填字段处理。
