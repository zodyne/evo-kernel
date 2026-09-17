---
id: doa-0deg-corner-unconstraining-cross-beam-consistency
type: lesson
status: candidate
scope: global
domain: radar-doa
tags: [doa, 测角, 阵列几何, 角反, 跨波束一致性, 校准]
triggers:
  - "审计/验证 DOA 阵列几何与通道排列是否正确"
  - "暗箱 0° 角反数据全绿，但怀疑几何/排列有错却无法证伪"
  - "多 Tx 波束（BPM/MIMO）测角结果与单 Tx 波束不一致"
  - "需要不依赖真值的判据来判定阵列几何假设"
  - "三波束角度极差异常，怀疑通道排列或 Tx 间距错"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7da-1c77-7719-ba82-31e9d9d40735
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [bpm-doppler-compensation-divide-by-tx]
---

0° 角反数据在原理上约束不了 DOA 几何——任何 Rx/Tx 排列或间距假设都会给出 0°，所以 0° 数据全绿无法证伪几何错误。

审计阵列几何/通道排列要用「单 Tx 波束跨波束一致性」判据：中/近是单 Tx 波束（没有 Tx 维度可以出错），两者用不同调频斜率、不同距离 bin，却必须给出同一个物理角度；双 Tx 的远波束与之对齐即证明几何正确。实测：修正通道排列统一为 (2,1,4,3) 并加 BPM 补偿因子 /Tx 后，暗箱 0° 三波束极差 0.75°、100m 靶极差 0.50°（修正前远波束与其他两波束明显偏离）。
