---
id: unverified-arxiv-ids
type: bullet
status: validated
scope: global
domain: research-methodology
tags: [arxiv, verification, hallucination]
triggers:
  - "按 arXiv id 下载论文"
  - "别人给的论文链接/id 清单"
  - "模型记忆里的文献引用"
created: 2026-07-23
evidence: {helpful: 4, harmful: 0}
verified_by: command
source: session:agent-evo-research
last_verified: 2026-07-23
superseded_by: null
schema_version: 1
---
网传或模型记忆里的 arXiv id 错误率不容忽视（一次任务给的候选 id 错 3 个：LightRAG、Gödel Agent、记忆综述，其中 2410.12829 实为电商论文）。

**做法**：下载前用 arXiv API 按标题核对 id（`search_query=all:"<title>"`），不匹配就搜索正确 id；GitHub README 的 arXiv 徽章链接是权威来源。
**边界**：核对本身受 429 限流，配合 arxiv-api-rate-limit 条目使用。
