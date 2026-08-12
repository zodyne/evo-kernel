---
id: mcp-stateful-tool-error-list-all-invalidation-causes
type: lesson
status: candidate
scope: global
domain: mcp-design
tags: [mcp, error-message, continuation-id, lru, stateful-tool]
triggers:
  - "给 MCP server / 工具设计带状态的会话句柄（continuation_id / thread_id / session 句柄）"
  - "写『句柄未找到』类错误消息"
  - "用户拿着 continuation_id 报错来问该重试还是重开（失败信号：错误消息只说 not found，不说明原因）"
  - "MCP server 用内存字典 + LRU 存会话历史，重启或逐出后旧句柄失效"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:5f8dee58-e3b6-4552-a0bf-8df757d08d5c
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [long-running-process-needs-restart-after-pip-install, stdio-mcp-server-jsonrpc-smoke-test]
---
带状态的 MCP 工具（内存会话表 + continuation_id）的"句柄未找到"错误消息，**必须列全所有可能失效原因**，否则调用方无法判断该重试、重开会话还是排查 server。推荐范式：`continuation_id '<id>' not found（可能已被 LRU 逐出，或从未创建，或 MCP server 重启过）`——一句覆盖容量逐出 / 笔误 / 进程重启三种正交原因。

证据：graph-lab multi_model_mcp.py（`MAX_CONVERSATIONS = 200`、`MAX_TURNS_PER_CONVERSATION = 20`，超出砍最旧）实测脚本调用 `get_thread_history('doesnotexist')` 返回上述错误消息，三种原因齐备。

边界：原因清单要如实覆盖实现里真实存在的失效路径；实现了持久化后"server 重启"一条应移除，不要照搬模板。
