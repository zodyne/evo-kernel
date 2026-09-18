---
id: mdpi-pdf-direct-link-403
type: lesson
status: candidate
scope: global
domain: research-tooling
tags: [mdpi, curl, http-403, fulltext-retrieval, citation-verification, bot-wall]
triggers:
  - "用 curl 抓 MDPI 论文的 /pdf 直链，准备核对引文原文"
  - "该直链返回 403 且 content-type 是 text/html（失败信号：拿到的不是 PDF）"
  - "核验出版商论文时，要判『抓不到全文』是链接写错还是站点侧拦截"
  - "想把出版商 PDF 直链写进可复现的下载步骤 / 脚本"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-53a8-73b1-bdd8-c2dbfa58d618
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [http-200-may-be-bot-check-page, curl-o-code-000-no-output-file, source-term-mismatch-downgrades-citation-support]
---

# MDPI 的 /pdf 直链对 curl 返回 403 text/html，不是可用的全文来源

## 一句话主张

MDPI 论文页的 `/pdf` 直链（本例 `https://www.mdpi.com/1424-8220/23/11/5271/pdf`）对普通
`curl -sL` 返回 **`403 text/html`**（不是 PDF，body 也只有几百字节），
这是站点侧拦截而不是"链接失效"：不能用它判断论文/引用不存在，也不能把它当成稳定的
全文下载路径；要核对原文就用已落盘的副本或其它途径，并把"HTTP 成功"与"拿到正文"分开判。

## 为什么

"核验引文"的任务里，"抓不到 PDF"最容易被归因到引用本身有问题（引用造假/论文不存在）。
这条观测说明：同一个 URL 可以是**站点拒绝服务**而非资源缺失——本例里同一篇论文的 PDF
此前已经落盘（`/tmp/mdpi.pdf`，12,958,010 字节），并在后续会话步骤里成功抽取了文本
（`/tmp/caffa.txt`，58,714 字节），说明"直链 403"与"全文不可得"是两件事。
把这类直链写进可复现流程，还会让"下载成功"的判据落在 HTTP 层而悄悄丢掉正文。

## 边界

- 单次观测、单一 URL（MDPI Sensors 23(11):5271）；**未验证**换 UA / Referer / 机构代理
  是否能过，也**不断言** MDPI 全站行为，只把它当"出版商 /pdf 直链可能被 403 拦截"的实例。
- 403 与 200 人机校验页（`http-200-may-be-bot-check-page`）、`code=000` 不落盘
  （`curl-o-code-000-no-output-file`）是三种不同失败形态，判据不能互相套用。
- 本条只讲"抓取通道"，不涉及该论文内容 / 引文是否被曲解（那是另一条线）。

## 证据（session 01a0b2ce 命令 ↔ 结果，切片逐字）

- `curl -sL --max-time 60 -o /dev/null -w "%{http_code} %{content_type} %{size_download}\n" "https://www.mdpi.com/1424-8220/23/11/5271/pdf"`
  → `403 text/html 408`（状态 403、类型 text/html、body 408 字节）。
- 同一结果块可见 `-rw-r--r--@ 1 zodyne wheel 12958010 Sep 15 20:06 /tmp/mdpi.pdf`
  ——同一篇论文的 PDF 早已落盘，"直链 403"并不代表全文不存在。
- 后继步骤 `ls -la /tmp/caffa.txt /tmp/mdpi.pdf` +
  `python3 -c "import fitz; d=fitz.open('/tmp/mdpi.pdf'); …"` → 本地副本可用
  （`/tmp/caffa.txt` 58,714 字节，`head -20 caffa.txt` 打出该论文标题
  `sensors Article Binary-Phase vs. Frequency Modulated Radar Measured Performances…`）。
