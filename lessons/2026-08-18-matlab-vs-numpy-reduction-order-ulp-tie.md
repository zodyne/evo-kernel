---
id: matlab-vs-numpy-reduction-order-ulp-tie
type: lesson
status: candidate
scope: global
domain: matlab-python-migration
tags: [float, ulp, argmax, reduction-order, numpy, matlab]
triggers:
  - "MATLAB 与 NumPy 求和结果差 1 ULP"
  - "argmax 在能量接近的单元选到不同分支"
  - "DDMA 子带选择移植后个别单元不同（失败信号）"
  - "写浮点断言时要不要逐位相等"
  - "MATLAB sum 顺序求和 vs numpy 归约成对求和"
created: 2026-08-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-18-21-59-04-668-k45z
last_verified: 2026-08-18
superseded_by: null
schema_version: 1
related: [float-noise-near-tie-decision-flip]
---

# 主张

MATLAB→Python 移植的 argmax 平局：**MATLAB `sum` 顺序求和、NumPy 归约成对求和，4 元素求和即可差 1 ULP**。若结果送入 argmax（如 DDMA 子带选择），会在能量接近的单元上选不同分支。

# 对策

断言时**排除 top1/top2 相差 <8 ULP 的单元**，而不是要求逐位相等。

# 证据

afm761 实测 24576 单元中 1 个。

# 与相邻条目的边界

本条给的是「同公式、不同归约顺序」这一具体机制与 ULP 量级阈值；`float-noise-near-tie-decision-flip` 记的是通用处置（≤N 个近平局单元差异 + 相对差判据 + 帧级门禁）。
