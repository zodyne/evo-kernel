---
id: citation-pure-number-ref-doi-misread-crossref
type: lesson
status: candidate
scope: global
domain: research
tags: [citation, doi, crossref, verification, reference]
triggers:
  - "核验文档/简报里的文献引用，发现某个页码或编号在原文 grep 全文搜不到"
  - "引用里出现纯数字串（836 / 738 / 599236 这类）却对不上任何页码"
  - "要把论文 DOI 反查成标题/作者/期刊，确认某条引用出处是否真实存在"
  - "发现文档里写的『第 836-844 页』其实是论文 DOI 尾号被误当成页码（失败信号）"
  - "用 crossref API 溯源文献编号 / DOI 的真实出处"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a572-2ae8-777c-a410-32590a6ce651
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [verify-external-references, unverified-arxiv-ids]
---
一句话主张：核验文档里的文献引用时，纯数字引用（"836-844" 这类）可能是论文 DOI 尾号被误当成页码；先用 crossref API 反查 DOI 溯源真实出处，再 grep 目标文档全文确认该数字是否真的以页码/编号形式存在——两条都能证伪"根本不存在的引用"。

为什么：对抗式核验 bpm_2t8r_sim 简报时，简报称"SPEC 写的 836-844"在目标文档里根本不存在——`grep -rn "836|C3-1|..." SPEC_multiframe.md README.md report/*.tex` 返回 exit=0 且无匹配（注释 1 = no match）。反向追 `836|738|599236` 的唯一命中是 `SPEC_multiframe.md:112:> DOI:10.1109/7.599236`，即 836 其实是 Ferrari 论文 DOI（10.1109/7.599236）的尾号，被误当成页码。再用 crossref 反查 `10.1109/7.599236` 得到 `Doppler ambiguity resolution using multiple PRF | IEEE Transactions on Aerospace and Electronic Systems`，坐实出处与"页码"无关。

边界/证据链接（均来自会话 01a0a572 的命令 ↔ 结果切片）：
- `rg -n "836|738|599236" --no-ignore -g '!*.pdf' .` → 唯一命中 `SPEC_multiframe.md:112` 的 `DOI:10.1109/7.599236`，说明这些数字的来源是 DOI 而非正文页码。
- `grep -rn "836|C3-1|C3-2|..." SPEC_multiframe.md README.md report/*.tex` → `exit=0 (1 = no match)`，即全文没有任何 836 页码，证伪"836-844"这条引用。
- crossref 命令 `for d in 10.1109/7.599236 ...; curl -s -m 12 "https://api.crossref.org/works/$d"` → `10.1109/7.599236 ['Doppler ambiguity resolution using multiple PRF']`，DOI 反查到真实论文，证明数字串是 DOI 尾号而非页码。
- 末条 assistant 收口：finding #1 驳斥的"SPEC 写的 836-844"在目标文档里根本不存在。整条链（grep 零命中 + crossref 溯源）是命令级硬证据。

反例/边界：纯数字引用不一定都是 DOI 误读，也可能是正文里的表格号、公式号、参考文献序号。核验顺序应是先 grep 目标文档看数字是否以"页码/编号"形态真实存在，搜不到再走 crossref 反查判断它是否来自 DOI——不要一见数字就默认是 DOI 尾号。
