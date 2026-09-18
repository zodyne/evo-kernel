---
id: pdftotext-md5-roundtrip-verify-corpus-integrity
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [citation, verification, pdftotext, corpus-integrity, md5]
triggers:
  - "要逐字核验文档里的文献引用，先确认所依据的论文文本语料没有损坏或截断"
  - "引用核验得出『原文里找不到』的结论，怀疑是抽取语料的问题而非引用造假"
  - "拿早前批量 pdftotext 产出的 .txt 语料做新一轮核验"
  - "重抽取后 md5 与在用文本不一致（失败信号）"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a525-f867-777c-a410-32542dd1bef4
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [arxiv-download-proxy-truncation, citation-pure-number-ref-doi-misread-crossref]
---

# 引用级核验前先做 pdftotext 重抽取 + md5 比对，确认语料完整再开核

## 主张

对已抽取成纯文本的论文/文献语料做逐字引用核验前，先用 `pdftotext` 对原 PDF 重新抽取一遍，并与在用的 .txt 逐个 md5 比对；全部一致才把该语料当核验 ground truth，开始逐字比对。

## 为什么

对抗式核验的判据是「简报引文能否逐字对上原文」，语料若在早期抽取环节损坏、缺页或被动过，会把语料问题误判成引用问题（假阳性/假阴性都可能出现）。重抽取 + md5 比对只花一次循环的成本，却给整场核验一个可指认的完整性基线。

## 边界

- md5 一致只证明「在用文本与本次重抽取一致」，不证明 PDF 原件内容正确；下载环节的截断/损坏由下载时校验负责（见 related: arxiv-download-proxy-truncation），两者互补。
- 语料含非确定性因素（如抽取器版本变化）时 md5 会假性不一致，此时改为逐段 diff 定位差异再判。

## 证据（命令 ↔ 结果，本会话切片）

- `cd refs && for f in ti-swra554a-mimo-radar ti-tiduf01-tidep-01027 mdpi-sensors-23-5271-bpm-vs-fmcw aess-sun-...; do pdftotext 重抽取; md5 比对; done` → 每个 ref 输出 `OK <name> <N> lines`（如 ti-swra554a-mimo-radar 535 lines、ti-tiduf01-tidep-01027 1117 lines），全部一致。
- 该基线建立后，全场对 TI SWRA554A / TIDUF01 §2.4.8 / Caffa / Sun / Xu / Shen & Wang 等引文的逐字核验结论才可指认到具体行号。
