---
id: community-research-rss-api-first
type: bullet
status: validated
scope: global
domain: web-scraping
tags: [web-scraping, research, rss, api, reddit, hackernews, build-vs-buy]
triggers:
  - "调研某工具/产品在社区（Reddit/Hacker News/论坛）里的口碑评价"
  - "批量抓取 Reddit / Hacker News / 论坛帖子做研究"
  - "curl 抓社区站/文档站返回空内容、403 或被截断"
  - "收集多个 SaaS 工具的定价/对比做 build-vs-buy 论证"
created: 2026-07-23
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:019f8dc7-3d7d-7966-86b6-f70c4e84f8c5
last_verified: 2026-07-23
superseded_by: null
schema_version: 1
---
做 agent/工具的社区口碑或 build-vs-buy 调研时，抓取社区站（Reddit、Hacker News、SaaS 官网等）**优先用 RSS feed 或结构化 API（如 HN Algolia API `hn.algolia.com/api/v1/...`）**，不要先去 HTML 直爬——后者常被反爬拦截，反复换 UA/headers 性价比低。

**做法**：
1. 优先找 RSS / API 端点：HN 用 Algolia API（`https://hn.algolia.com/api/v1/search?query=...` 或 `/items/<id>`，返回 JSON）；Reddit 用 `r/<sub>/.rss`；博客/官网常有 `/rss`、`/feed`、`/blog/rss`。RSS 用轻量 python 解析（`re.findall(r'<item>.*?</item>')` + `html.unescape`）。
2. 必须抓 HTML 时：用完整浏览器 headers（UA + Accept + Accept-Language + Accept-Encoding），且清洗**不能只 `sed 's/<[^>]*>/ /g'`**——会残留 `<script>/<style>/<svg>/<noscript>` 块垃圾；需 python 先 `re.sub(r'<(script|style|svg|noscript)[^>]*>.*?</\1>', ' ', h, flags=re.S|re.I)` 再 strip tags + `html.unescape`。
3. 遇到 403 / 空内容不要只靠换 UA 硬刚（sequential + `sleep` 重试效率低），先回头找 RSS/API 端点。
4. GitHub 调研走标准路径：repo 元数据用 `api.github.com/repos/<o>/<r>`，README/源文件用 `raw.githubusercontent.com/<o>/<r>/<branch>/...`，最稳。

**反例/边界**：Reddit 即使用浏览器 headers 仍可能限流；官方文档站（Claude docs、Cursor docs）有时没有 RSS、必须 HTML + 浏览器 UA，这类直爬不可避免。本条只主张"端点选择优先级"，不保证每个站都有 RSS。

**证据**：agent-evo 框架重设计会话中，调研社区对 agent 记忆 / Claude memory 的讨论——Reddit HTML 直爬受阻（出现 "retry (sequential, longer delay)" + `sleep 5` 重试），转用 HN Algolia API（会话内命令注释 "reliable, no anti-scrape"）+ Reddit/SuperMemory RSS 解析（`sh_basic_mem.rss`）；HTML 清洗多次出现上述 python 多步 strip；GitHub 调研全程 `api.github.com` + `raw.githubusercontent.com`。**注**：这些抓取命令的 stdout 结果在 distill 切片里被截断，无法直接确认 command 级结果对照，故 verified_by 诚实标 human（策略路径由真实命令佐证，结论为执行者综合判断）。
