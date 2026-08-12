---
id: agentic-search-tool-value-is-truncation-not-capability
type: lesson
status: candidate
scope: global
domain: agent-tool-design
tags: [web-search, searxng, context-budget, tool-design, truncation]
triggers:
  - "纠结要不要给 agent / MCP 工具集加 web 搜索工具"
  - "agentic 循环里工具返回原始搜索 JSON，几轮就把上下文撑爆（失败信号）"
  - "设计 MCP 工具的返回值：原始 API 响应 vs 截断摘要"
  - "评估『已有 bash+curl 还要不要专用搜索工具』这类能力重复问题"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:5f8dee58-e3b6-4552-a0bf-8df757d08d5c
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: []
---
给 agentic 工具集加 web 搜索时，若 bash 本身无网络隔离（已验证 `curl` 未被拉黑），专用搜索工具**没有解锁新能力**——模型早就能自己 curl。它的真正价值在**上下文预算**：原始搜索 JSON 一次查询 5–15KB，agentic 跑几轮就撑爆上下文；专用工具把结果压成截断过的摘要才是核心收益。评估"要不要加 X 工具"时先问：它省的是能力还是 token。

证据：graph-lab multi_model_mcp.py 加 web_search 前，先验证 SearXNG（localhost:8888）原始 JSON 返回体量、确认 bash 黑名单（`BLOCKED_BASH_PATTERNS`）不含 curl，再经 kimi+glm 双模型共识得出"值得加"，核心理由即原始 JSON 压缩。

边界：若宿主环境禁用了 bash 网络访问，结论反转——专用搜索工具变成能力解锁，价值更大。
