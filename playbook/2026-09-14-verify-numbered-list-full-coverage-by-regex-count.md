---
id: verify-numbered-list-full-coverage-by-regex-count
type: lesson
status: validated
scope: global
domain: evaluation
tags: [annotation, verification, full-coverage, retrieval-bench]
triggers:
  - "给检索/评测系统做人工标注，产出 ground truth 标准答案"
  - "要声称某份编号清单共 N 条、已全量看/标完，但 N 的来源没交代"
  - "处理一个长编号清单（claims / requirements / manifest / 测试用例），要证明无漏条、无重复、无首尾截断"
  - "标注集文件很长，肉眼扫过就声称全量覆盖（失败信号）"
  - "清单首末条 id 核对不上，或正则数出的总数与预期不符（失败信号）"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09f4d-d02c-7129-be3e-248c7ca82c43
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [recall-failure-empty-vs-noise-taxonomy, refs-json-count-range-contiguity]
---

# 主张

给评测集做人工标注（或处理任何编号条目清单）时，「全量覆盖」不能靠肉眼断言——先跑一条正则数出条目总数并核对首末 id，作为无漏条、无重复、无首尾截断的机器证据，再逐 query/逐条标注。

# 为什么

肉眼「扫了一遍」无法自证覆盖：长清单要么中间看漏，要么文件首尾被截断/多粘了一段，要么条目重复编号，这些都只在总数或首末锚点上暴露。一条 `re.findall(r'^\s*\d+\.\s+(\S+)')` 同时产出三件事——条目总数、首条 id、末条 id——总数对得上预期 + 首末 id 各就各位，才证明这份清单被完整读入且编号自洽。它把「我看完了」从一个主观声明变成可对账的机器证据，也让后续「共 N 条」的结论有出处。

# 反例 / 边界

- 只适用于**有稳定编号锚点的清单**（数字编号 + 每行一条）。无编号的自由文本或结构化格式（JSON/YAML/XML）不适用正则数条——结构化格式该用 json/yaml/plutil 解析，正则易被换行、空格、内嵌冒号骗过去。
- 正则数出的总数只证明「读了 N 条」和「首末对得上」，**不证明每条都被正确标注**；逐条标注的正确性仍需人工/规则判定。
- 若清单由程序生成、自带 manifest 或行数已知，直接对 manifest 更省事；正则只是无 manifest 时的兜底取证。
- 外部生成/维护的编号产物，验收三件套应是**条目数 + id 两端(min/max) + 序列连续**：只看 n 抓不住中段缺号——预期 54..121 共 68 条时，中段丢 1 又重 1 条 n 仍是 68；把 `sorted(id)` 与 `range(min, max+1)` 逐点比对才能暴露缺口/重号，生成方自报的「共 68 条」不能直接沿用。

# 证据

2026-09-14 会话里对 evo-kernel 检索评测集做人工标注，先通读 `SPEC.md` + 全量 `queries.json` + `claims.txt`，用正则取证条目总数：

```
$ python3 -c "import re; t=open('claims.txt').read(); ids=re.findall(r'^\s*\d+\.\s+(\S+)')"
  ↳ 76 2026-07-27-git-mv-bulk-verify-byte-identical-renames | warn-rule-must-be-visible-to-user
```

末条结论据此外显核对：「通读确认：claims.txt 共 76 条（regex 校验：76，首 2026-07-27-git-mv-bulk-verify-byte-identical-renames，末 warn-rule-must-be-visible-to-user）。三个 query 每个都过了全部 76 条」——总数 + 首末锚点三重对齐，作为全量覆盖的落盘证据。
