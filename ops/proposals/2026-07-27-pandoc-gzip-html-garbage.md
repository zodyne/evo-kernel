---
id: pandoc-gzip-html-garbage
type: lesson
status: candidate
scope: global
domain: web-archival
tags: [pandoc, gzip, html-to-markdown, web-scraping]
triggers:
  - "用 pandoc 把抓到的网页 HTML 转 markdown，输出是乱码或几乎为空"
  - "批量抓取网站存档成 markdown（OpenAI / Next.js 类站点）"
  - "pandoc html→gfm 产出异常短或全是不可读字符"
  - "curl 保存的 .html 文件 pandoc 解析失败"
  - "HTML 转 markdown 前忘了处理 gzip 传输编码"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019f8a68-b1c6-7794-80e8-e6afa0c28aa1
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
OpenAI 等 Next.js 站点对 HTML 响应做 gzip 传输编码；若 curl 保存时未解压（或经代理时透明解压不一致），落盘的是 gzip 字节流，pandoc 当 HTML 解析 → 乱码或近乎为空。

**诊断**：`file -b x.html` 显示 "gzip compressed data"，或 `head -c 4` 是 `\x1f\x8b`。
**修复**：先 `gunzip`（或 `python3 -c "import gzip; ..."`）解压，再 `pandoc -f html -t gfm`。
**证据**：agent-evo 会话中 OpenAI 的 `new-tools-for-building-agents`、`memory-and-new-controls` 两篇，pandoc 直接转出垃圾；注释明确写出 "Files are gzip-compressed! Decompress existing ones with gunzip"，解压后重跑 pandoc 才得到 `MEMORY AND NEW CONTROLS (clean)` 干净正文。
**边界**：从一开始用 `curl --compressed`（自动协商解压）即可规避，不必事后 gunzip。
