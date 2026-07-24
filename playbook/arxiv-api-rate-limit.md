---
id: arxiv-api-rate-limit
type: bullet
status: validated
scope: global
domain: web-scraping
tags: [arxiv, api, rate-limit]
triggers:
  - "arXiv API 返回 429"
  - "批量查询 arxiv 元数据"
  - "export.arxiv.org 请求失败"
created: 2026-07-23
evidence: {helpful: 3, harmful: 0}
verified_by: command
source: session:agent-evo-research
last_verified: 2026-07-23
superseded_by: null
schema_version: 1
---
arXiv API 对连续请求限流严格：并发 ≥3 即触发 HTTP 429。

**做法**：单请求串行 + 间隔 ≥5s，遇 429 退避 ≥60s；API URL 需 `curl -L`（301→HTTPS 重定向，否则返回空）。PDF 下载主机（arxiv.org/pdf/）限流比 API 松。
**证据**：agent-evo 研究两个 worker 各自独立踩到 429，同一解法均恢复。
