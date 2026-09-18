---
id: semanticscholar-pdf-direct-link-paywalled-fulltext
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [paper-fulltext, semanticscholar, pdf, citation-verification, pdftotext]
triggers:
  - "逐字核验付费墙论文（IEEE/IET/Elsevier）的引用，手上只有 DOI"
  - "只有 title/abstract 元数据，正文句子 grep 不到（失败信号：拿摘要当全文下结论）"
  - "要从 pdfs.semanticscholar.org 直链整篇下载论文 PDF 再 pdftotext"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7b5-62c3-777c-a410-326eedc45b7c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pdftotext-md5-roundtrip-verify-corpus-integrity, citation-pure-number-ref-doi-misread-crossref, arxiv-download-proxy-truncation]
---

# 付费墙论文的逐字核验：走 pdfs.semanticscholar.org 直链拿全文，再 pdftotext 抽文本

## 主张

引用核验要落到"原句是否这么写"时，先想办法拿到**出版版全文 PDF**：本会话里 Semantic Scholar 的 `pdfs.semanticscholar.org` 直链可整篇下载（`curl -sL -o x.pdf "<直链>"`），随后 `pdftotext -layout` 抽出全文再逐字 grep。只查 title/abstract/venue 元数据（S2 graph API、Crossref）只能验"这篇文献存在、卷期页对不对"，**验不了"原句这么写过"**——两部分证据不能互相替代。

## 证据（session 01a0a7b5 切片，命令 ↔ 结果）

- `curl -sL --max-time 60 -o gonzalez_iet.pdf "https://pdfs.semanticscholar.org/f1f3/0cf9388e863b67da0a10e320d8e6196b1ace.pdf"` → `2592126` 字节，`gonzalez_iet.pdf: PDF document, version 1.7`（一次性拿到整篇，非摘要页）。
- `pdftotext -layout gonzalez_iet.pdf gonz.txt` → 抽出 `1125` 行文本；文本首部即 `Received: 30 June 2020  DOI: 10.1049/rsn2.12063`，确认下载到的就是目标 DOI 的出版版全文。
- 随后的引用核验就在 `gonz.txt` 上做逐字短语检索（`"commonly used modulation"`、`"direct compatibility"`、`"remain intact"`、`"full exploitation"` 等多轮 grep），元数据侧另用 Crossref 反查（`vol 15 issue 8 page 884-901 year 2021`）对账——两条证据链并存。

## 边界 / 反例

- **不要用 `file` 判页数/完整性**：同一份 2.6 MB 全文，`file` 报 `1 pages`，而 pdftotext 抽出 1125 行。页数与截断判定用 pdftotext 行数或 `pdfinfo` 复核（与 `arxiv-download-proxy-truncation` 同一条纪律）。
- 直链可得性随论文/站点变化；拿不到全文时只能停在元数据级核验，结论要显式降级为"未核到原句"，不能把摘要级证据写成逐字证据。
- 本条只解决"拿到全文"这一步；全文在手之后，引文是否成立仍需另判出处（见 `citation-pure-number-ref-doi-misread-crossref`）与支撑强度（见 `source-term-mismatch-downgrades-citation-support`）。
