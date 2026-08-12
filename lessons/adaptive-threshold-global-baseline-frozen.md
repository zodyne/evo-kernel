---
id: adaptive-threshold-global-baseline-frozen
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: methodology
tags: [adaptive-threshold, causality, frozen-baseline, quantile, evaluation-integrity]
triggers:
  - "实现自适应阈值：用全局分位数归一每帧分位数"
  - "换评估数据集后顺手把自适应基线也重算了（失败信号：循环论证）"
  - "在线自适应机制要用未来/全局信息，因果性存疑"
  - "自适应改动的效果评估，基线口径前后不一致"
created: 2026-07-25
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:8eefe3a4
last_verified: 2026-07-25
superseded_by: null
schema_version: 1
related: [recalibrate-thresholds-before-comparing-sets, calibration-set-not-validation-set]
---

# 自适应阈值的全局基线必须冻结：随评估数据重算就是循环论证

**主张**：自适应阈值机制（`alpha_t = frame_q / global_q`，`thresh_t = base × clip(alpha_t)`）里的**全局分位数 global_q 是标定产物，必须冻结**，一次标定后不随新数据集重算。重算有两个后果：① 因果性破——在线部署时没有"新数据集的全局分位"可用，评估用了运行时拿不到的信息；② 循环论证——基线跟着评估数据走，自适应的增益/代价都被吃掉，测不出真实效果。

**边界**：与 recalibrate-thresholds-before-comparing-sets 的方向相反但互补：那条讲改算法后**阈值要重标**才能公平比较；本条讲自适应机制里**基线不能随评估数据动**。区分点：重标发生在"算法变更后的定标阶段"（一次性），冻结针对"评估/运行阶段"。每帧实际用的阈值要写入输出字段（如 `fa_thresh`）便于事后审计。

**证据**：session 8eefe3a4（自适应阈值实现，0709_1/0709_2 固定 vs 自适应对照表）+ da720f38 报告修订（`global_p` 必须冻结且不随数据集重标的因果性论证）。
