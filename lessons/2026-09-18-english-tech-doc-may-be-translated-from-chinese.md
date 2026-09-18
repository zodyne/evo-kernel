---
id: english-tech-doc-may-be-translated-from-chinese
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [translation, provenance, ti, sourcing, verification]
triggers:
  - "把英文技术文档（TI 技术文章/应用报告）当作一手工程做法引用或核验"
  - "文档文首出现 'This document was translated from a simplified Chinese source.' 一类翻译声明（信号）"
  - "被核验的公式/数值来源是译文，与其它来源对不上"
  - "要判定某工程做法到底是一手、译文还是转述"
  - "TI PDF 里出现 (ZHCTA17) 这类括号编号，不知道它指的是什么"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7b9-3ee0-777c-a410-327021f18732
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [verify-external-references, citation-pure-number-ref-doi-misread-crossref]
---

# 英文技术文档可能是中译英：引用前先读文首的翻译声明

## 主张

把一份英文技术文档（本次是 TI 的 DDMA 技术文章 `ti-ssztdd9-ddma-awr1843.pdf`）当作「一手工程做法」引用或核验之前，**先读文首有没有翻译声明**。该 PDF `pdftotext` 后第 9 行逐字写着：

```
This document was translated from a simplified Chinese source. (ZHCTA17)
```

即它是译文，括号里的 `ZHCTA17` 指向原始（中文）文档。自述为译文时，公式与数值的核验应回到原文出处，而不是把英译本当权威源背书。

## 为什么

文档的**权威等级取决于它是不是原文**，而语言不是判据——英文 PDF 很容易被默认成「英文一手源」。译文继承原文的结论却可能丢失上下文（公式排版、符号约定、图注），核验时对不上会误判成「原文/简报写错了」。而翻译声明就一句话、位置固定在文首，成本极低：`pdftotext <pdf> - | head -20` 或 `pdftotext <pdf> - | grep -in "translated\|translation"` 即可判定。

## 证据（切片命令 ↔ 结果，逐字摘）

```
$ cd …/bpm_2t8r_sim/refs && pdftotext ti-ssztdd9-ddma-awr1843.pdf - 2>/dev/null | grep -in "ZHCTA\|translated\|simplified Chi…
  ↳ 9:This document was translated from a simplified Chinese source. (ZHCTA17) exit;0 === cnblogs fetch === -rw-r--r--@ 1 zo…
```

同一切片里，判定为译文后本次会话随即转去抓中文技术社区的页面（`/tmp/cnblogs.html`），并把中文段落抽出（`### kw=三、总结 @7528 回波中检测出的速度值相差：…`）——即「回到原文核对」这一步被实际执行。

## 边界 / 未做的确认

- **不推广到「所有英文技术文档都是译文」**：只有自述翻译的才按译文处理；没声明就是普通文档。
- 切片只能证明抓到了一份含中文段落的页面，**不能证明**它就是 `ZHCTA17` 所指的那份原始中文文档——引用时要另外坐实原文出处（DOI/编号/发布方），别把「搜到的中文博客」直接当原文。
- 译文本身仍可作二手依据使用；本条要求的是**标注等级并回源核对**，不是弃用。
