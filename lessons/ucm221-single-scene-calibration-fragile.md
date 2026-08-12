---
id: ucm221-single-scene-calibration-fragile
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: signal-processing
tags: [calibration, threshold, generalization, gt-scarcity, faf]
triggers:
  - "faf/过滤器阈值只在 0709_2 单场景标定"
  - "跨场景泛化断言或现场验证计划"
  - "可用 GT 场景盘点（失败信号：标定集自身无可信 GT）"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:b0e19d24
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
---
# 单场景标定是 faf 脆弱性根源；可用 GT 场景实际只有 2 个

**主张**：faf 四个阈值（rho/hpr/dc/snr_floor）全部在 0709_2 单场景（500 帧/195,642 点）标定，跨场景泛化未验证是首要风险；多场景摸底结论——**可用 GT 场景只有 000028（63 条长命径向航迹，6 条人工确认）和 000034（5 条）两个**；0709_1/0709_2 的"运动"航迹同时同向径向移动，像自运动杂波假动，不能当 GT（即标定集自身没有可信真值）；000027 只能当纯虚警场景。在标定集上评估过滤效果是同源的，好看是应该的，不构成证据。

**为什么**：权重报告实证——现行权重距崩塌仅 12–25% 余量（KEEP 降到 250k 覆盖率崩到 77%），Fisher 权重在 121k 点仍稳；重标数据集的选择对断裂数的影响大于权重本身（66 次→11 次）。泛化断言前必须先做多场景 GT 摸底。

**边界**：摸底判据是"legacy 长命且径向运动的航迹"，换数据集要重盘；结论随新数据采集过时。

**证据**：session b0e19d24 五场景摸底表 + 权重鲁棒性权衡曲线。
