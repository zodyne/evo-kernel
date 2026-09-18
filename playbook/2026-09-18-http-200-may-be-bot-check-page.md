---
id: http-200-may-be-bot-check-page
type: lesson
status: validated
scope: global
domain: web-scraping
tags: [curl, http-200, anti-bot, scraping, verification]
triggers:
  - "curl/爬虫抓页面返回 200 且 content-type 是 text/html，但正文里找不到要核对的句子"
  - "抓到的 HTML <title> 是 'Making sure you're not a bot!' 一类人机校验标题（失败信号）"
  - "只看 http_code==200 就宣布下载/抓取成功（失败信号）"
  - "核验外部引文时得出『原文里没有这句话』，准备判引用造假"
  - "批量抓文档站/论文站点，需要判断哪些页面真拿到了正文"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7b1-a576-777c-a410-326c0e8fea05
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [community-research-rss-api-first, curl-o-code-000-no-output-file, pdftotext-md5-roundtrip-verify-corpus-integrity]
---

# HTTP 200 + text/html 也可能是反爬人机校验页：抓取成功必须再验正文

## 一句话主张

抓网页做核验/提取时，`http_code==200` 且 `content-type: text/html` **不等于**拿到了正文——它可能是反爬/人机校验中间页；必须在解析前再验一步正文身份（`<title>`、已知标记或预期关键词），否则会把「没抓到」误判成「原文里没有」。

## 为什么

本次对抗式核验中，一个待核页面的抓取结果是标准的"成功"形状——`200`、`12613` 字节、`text/html; charset=utf-8`——但正文第一行就是
`<!doctype html><html lang="en"><head><title>Making sure you&#39;re not a bot!</title>`，
即人机校验页（Anubis 类）。状态码、content-type、体积三项都正常，只有标题/正文能暴露它。
这类"200 形状的静默失败"最危险的下游后果是：拿这个空壳去核引文，会得出「原文查无此句」的假阴性，
把抓取失败误判成引用不实——恰好污染核验结论本身。

## 反例 / 边界

- 体积阈值不可靠：部分站点的校验页也很大（>100KB，内含 JS 挑战）。优先查 `<title>`/已知标记，或直接断言正文含预期关键词。
- 拿到校验页后不要反复换 UA 硬刚（拦截常与 UA 无关），改走可访问的替身源：论文 PDF / HTML 全文版、RSS/API、镜像（见 related）。
- 本条只讲「200 也可能是假成功」；连接失败不落盘（code=000）与下载成功但截断损坏是另两类失败，判据不同（见 related）。

## 证据

命令 ↔ 结果（session 01a0a7b1 切片；原命令末尾被切片截断，UA 为 Safari 风格浏览器串）：

```
$ cd /tmp/chk && curl -sSL -m 45 -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1." …
  ↳ 200 12613 text/html; charset=utf-8 <!doctype html><html lang="en"><head><title>Making sure you&#39;re not a bot!</title>
```

对照：同一会话换源后抓取成功（arXiv `200 42590 text/html` 并成功抽出标题 `[2307.01444] Static Background Removal in Vehicular Radar…`，TI PDF `200 1132103 application/pdf` 且 `pdftotext` 后可 grep 到正文）——说明"200 + 可解析正文"才是成功判据。
