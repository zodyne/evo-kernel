---
id: source-term-mismatch-downgrades-citation-support
type: lesson
status: validated
scope: global
domain: research-methodology
tags: [citation, reference-verification, terminology, grep, term-count]
triggers:
  - "核验『某文献支撑某术语/技术』的引用断言（近义术语混用：BPM/PMCW、TDM/DDMA 这类）"
  - "引文的本地文件名或标签与论文正文用语不一致（文件名写 bpm-vs-fmcw，正文却只用 PMCW）"
  - "grep 源文本时目标术语 0 命中、另一个术语几十命中（失败信号：把概念等价当成逐字佐证）"
  - "要判断一份引用密集的简报是『引文属实』还是『源支撑被抬高』"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7b5-62c3-777c-a410-326eedc45b7c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [citation-pure-number-ref-doi-misread-crossref, verify-external-references, located-quote-claims-must-be-grepped-in-source, pdftotext-md5-roundtrip-verify-corpus-integrity]
---

# 引用归属要用源文本的术语计数判：目标术语 0 命中 ⇒ 该文献不能算"逐字佐证"

## 主张

核验"某文献支持术语 T 的断言"时，先对源全文做**术语计数**（`grep -o -i "\bT\b" <源文本> | wc -l`）。若 T 命中 0、而另一个术语 S 命中几十次，则这份文献只能按"另一个术语口径下的相关工作"对待——**不能当作用 T 那个词写下的逐字佐证**；否则引用标签（文件名、引用方自述）就被当成了源文本证据。

## 为什么

本地文件名与引用标签是人写的，抄写时天然会把近义术语归一；源文本才是引用归属的事实。一次核验里，项目 refs 下被命名为 `mdpi-sensors-23-5271-bpm-vs-fmcw.pdf` 的对照论文，正文里 `BPM` 出现 **0** 次、`PMCW` 出现 **77** 次：标签说的是 BPM，文本只谈 PMCW。这类"标签 ≠ 文本术语"不会让引文本身变假，但会让"该源逐字支持了 T 的说法"这一步站不住——它至多支持"存在一类等价概念"。

## 证据（session 01a0a7b5 切片，命令 ↔ 结果）

- `pdftotext -layout mdpi-sensors-23-5271-bpm-vs-fmcw.pdf /tmp/caffa.txt` → 抽取成功（后续多轮短语 grep 均在这份文本上做）。
- `grep -o -i "\bBPM\b" caffa.txt | wc -l` / `grep -o -i "\bPMCW\b" caffa.txt | wc -l` → `BPM count: 0`、`PMCW count: 77`（命令原样来自切片，计数是硬结果）。
- 同一会话收口结论：「简报质量：overstated（不是 wrong —— 大部分引文逐字属实；问题集中在几处『源支撑被抬高』）」——"标签说 X、文本只说 Y"正是可命令复现的一处形态。

## 边界 / 反例

- **0 命中只否掉"逐字支撑"，不否掉"这条引用与断言相关"**：源可能只是用了另一术语描述同一类对象，结论应写成「该源用的是 S 口径，需按概念等价对待或另找 T 口径的直接源」，不能据此判引用造假。
- 计数要对**同语言/同大小写口径**做（`-i`、`\b` 词边界），否则会数到 `BPM-MIMO`、`BPM 的` 之类子串，或漏掉复数/连写变体。
- 与 `citation-pure-number-ref-doi-misread-crossref` 互补：那条判"引文是否真实存在/出处对不对"；本条判"引文存在、但术语归属被抬高"。
