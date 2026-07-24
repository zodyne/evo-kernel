---
id: arxiv-download-proxy-truncation
type: bullet
status: validated
scope: global
domain: web-scraping
tags: [arxiv, pdf, proxy, curl]
triggers:
  - "下载大 PDF 文件损坏"
  - "pdf 打不开 / 缺页 / 0 页"
  - "批量下载论文"
  - "curl 下载被截断"
created: 2026-07-23
evidence: {helpful: 3, harmful: 0}
verified_by: command
source: session:agent-evo-research
last_verified: 2026-07-23
superseded_by: null
schema_version: 1
---
本机代理（127.0.0.1:7897）会间歇性截断大文件下载（11MB 级 PDF 多次损坏：无 %%EOF、XRef 表缺失但 `file` 仍误判为 PDF）。

**做法**：`curl --noproxy '*' -C - --retry 15 --retry-all-errors`（直连 + 断点续传 + 重试），并用 `pdfinfo` 页数或文本抽取校验，不轻信 `file` 输出。
**反例/边界**：小文件（<1MB）一般不受影响；arXiv PDF 用显式 `.pdf` 后缀 URL 更稳。
**证据**：agent-evo 研究中 Voyager/ExpeL/综述等 4 篇首次下载均损坏，换参数后 29/29 通过。
