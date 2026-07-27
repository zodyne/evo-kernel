---
id: pandoc-gfm-residual-html-tags
type: lesson
status: candidate
scope: global
domain: web-archival
tags: [pandoc, html-to-markdown, cleanup, web-scraping]
triggers:
  - "pandoc -t gfm 转换后 markdown 里残留 <div>/<img>/<span> 标签"
  - "批量 HTML→markdown 存档，正文夹着原始 HTML 标签"
  - "pandoc gfm 输出不干净需要后处理"
  - "网页转 markdown 后 img/div 没被转换成纯文本"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019f8a68-b1c6-7794-80e8-e6afa0c28aa1
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
pandoc 的 gfm（GitHub-Flavored Markdown）writer 对无法映射的 HTML 元素（div/img/span 等）会**原样透传**，导致输出 markdown 里夹着原始 HTML 标签，不够干净。

**做法**：转换后用正则后处理剥离——`re.sub(r'</?(div|img|span)\b[^>]*/?>', '', md)`，再折叠多余空行。
**证据**：agent-evo 会话中针对 Anthropic 文章写了 `/tmp/clean_md.py`（`re.sub(r'<img\b[^>]*?/>', '')`），针对 Google（AlphaEvolve 等）文章反复用 `md = re.sub(r'</?div[^>]*>','',md)`，并提炼出通用 `clean(fn)` 对 google-msft 全目录批量清洗——多文件复现同一问题。
**边界**：想保留图片信息可把 `<img src=...>` 转成 markdown `![](url)` 而非直接删；`<script>/<style>` 整块应连同内容一起删除，不要只删标签。
