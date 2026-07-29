---
id: nan-score-key-breaks-comparison-sort
type: lesson
status: validated
scope: global
domain: algorithm
tags: [javascript, nan, sorting, scoring, numeric]
triggers:
  - "写打分/权重函数，公式里有除法或 log，分母可能为 0"
  - "排序结果错乱：本该排前的条目掉到末尾或随机乱跳"
  - "recall/检索/推荐打分里 helpful==harmful==0 的条目行为异常"
  - "score 字段偶尔是 NaN，且比较时不出错也不报错（失败信号）"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# 打分函数算出的 NaN 做排序键会击穿比较排序——必须兜底成有限正数

**主张**：权重/打分公式若可能产出 `NaN`（如 `log(1+0-0)=0` 再做 `x/0`、或 `0/0`），把 NaN 作为 sort 比较键时，`NaN < x` 和 `NaN > x` **恒为 false**——排序器无法定位它的位置，结果要么把它扔到末尾要么随机错位，且**全程无异常无报错**。整个排行榜静默失真。

**根因**：JS 的 NaN 不等于任何值（含自身），比较运算恒 false；`Array.sort` 的比较器返回 0/负/正时遇到 NaN 比较会退化。

**修法**：在打分出口强制兜底——`score = Math.max(eps, rawScore)` 或 `Number.isFinite(rawScore) ? rawScore : floor`，确保进入排序的永远是有限数。本次修复即 `evW = Math.max(0.3, ln(1+h-hm))`，h=hm=0 时给 0.3 下限而非裸 0（0 做后续分母仍可能再生 NaN）。

**反例/边界**：若公式数学上保证恒正（无除法/log），可不兜底；但只要存在 `÷` 或 `log` 且输入含 0，就必须兜底——别赌调用方传什么。

**证据**（commit 1897fa4）：
- 复现：govWeight 在 helpful=0/harmful=0 时算出 NaN，击穿 recall 打分排序。
- 修复：`evW = Math.max(0.3, Math.log(1 + h - hm))`，实测 `helpful=0 harmful=0 → evW=0.3`。
- smoke 新增 `D2: govWeight 对任意 helpful/harmful 恒为有限正数（NaN 击穿守护）`。
