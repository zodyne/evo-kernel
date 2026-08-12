---
id: ucm221-lab-to-field-transfer-check-coverage
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: signal-processing
tags: [ccmf, field-data, lab-to-field, noise-floor, coverage-check]
triggers:
  - "暗室标定/验证通过的算法往现场数据迁移"
  - "现场数据一致性代价比合成纯噪声还差（失败信号）"
  - "现场数据里目标场景的样本数为 0"
created: 2026-07-25
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:2d621583
last_verified: 2026-07-25
superseded_by: null
schema_version: 1
---
# 暗室验证通过不等于现场可迁移：先查现场数据对目标场景的覆盖，并用合成噪声地板对照

**主张**：暗室验证过的算法（如 CCMF-Re/Im 共阵标定，暗室 LOO 3.14°）迁到现场数据前必须两查：① 现场数据是否覆盖算法要解决的目标场景——0709_2 现场 30000 点中 |el_fpga|>30° 的点数为 **0**，CCMF 最想解决的大角度场景现场无样本，"验证"无从谈起；② 一致性指标与**合成纯噪声地板**对照——现场 min_cost 中位 0.221，比合成纯噪声（0.12）还差，说明模型在现场根本不拟合，而非"精度略降"。

**为什么**：CCMF 现场与 FPGA 俯仰相关仅 0.209、|Δel|>5° 占 49%、low_conf 率 87.1%——没有噪声地板对照时这些数字容易被读成"迁移损失大"，有对照才能判定"完全未迁移"。另外注意生产验收门可能事实上失效：暗室真目标 pass_prod=0%（estu_fallback 100% 触发必然回退），门限设计需独立于标定结论重验。

**边界**：结论针对 0709_2 这批现场数据；新现场采集（含大角度样本）后需重估。

**证据**：session 2d621583 汇总的 field_0709_analysis（0709_2 30000 点）与 ccmf_suppression_validation 结果。
