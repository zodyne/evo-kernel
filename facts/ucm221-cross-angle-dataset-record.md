---
id: ucm221-cross-angle-dataset-record
type: fact
status: validated
scope: project:ucm221
domain: radar-signal
tags: [ucm221, 十字测角, 数据集, 外场, 出圆]
triggers:
  - "找 UCM221 十字测角外场数据集（08-05）"
  - "复现/更新十字测角分析报告"
  - "大俯仰角段出现 az 伪点，怀疑相位模糊"
  - "需要出圆率的参考数值"
created: 2026-08-07
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-07-06-39-01-011-bbpi
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [episode-ucm221-out-of-circle-az90-algorithm-defect, parser-silent-clamp-masks-out-of-range]
---
UCM221 十字测角数据集（`data/十字测角`，08-05 外场）实测特征记录：

- 目标角反 R≈20m（SNR 中位 29dB）；
- 横臂 3 段：az ±47°，el std ≤2.3°；
- 竖臂 4 段：az 收敛 +7~9°，最优 std 1.19°；
- el 大角度段（极值 −36~+47°）有相位模糊 az 伪点（达 +82°）；
- 出圆率 13.96%。

**分析入口**：`python/analyze_cross.py` → 产出 `report/十字测角_测试报告.pdf`。

**边界**：大角度段的 az 伪点与 `episode-ucm221-out-of-circle-az90-algorithm-defect` 同族——引用该数据集结论前先排除伪点段。
