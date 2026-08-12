---
id: proxy-metric-contradicts-end-to-end
type: lesson
status: candidate
scope: global
domain: evaluation
tags: [proxy-metric, ground-truth, tracker-as-validator, pointcloud-filter]
triggers:
  - "用中间层代理指标（点级召回/精度）优化级联系统"
  - "代理指标改善但端到端指标恶化（失败信号）"
  - "给点云过滤器/预处理器选验收判据"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:b0e19d24
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
---
# 代理指标与端到端真值可能给出相反结论，最终以端到端为准

**主张**：级联系统（如 点云过滤器→跟踪器）的中间层优化，代理指标（点级 GT 召回）与端到端真值（航迹断裂次数）可能**方向相反**——代理说改对了（召回 95.59%→98.16%），端到端验证却是退化（断裂 10 次→66 次）。最终判定必须用端到端指标；评估过滤器时**用下游跟踪器当验证器**（覆盖率/断裂/最长断裂/ID 数/误差中位），点云标签只在归因时作证据。

**为什么**：过滤器真正要保的是"航迹能续上"所需的关键帧点（任何检测中断后的第一帧 persist=0 正是航迹续命帧），点级平均召回对这个结构性目标不敏感。另外权重与判定阈值是耦合系统：同一组权重只换重标数据集，断裂 66 次→11 次——**重标口径的影响大于权重本身**。

**边界**：端到端评估需要可信 GT（本例 6 条人工确认 legacy 航迹 3895 帧）；GT 场景稀缺时结论外推要谨慎。

**证据**：session b0e19d24 gt_eval 报告：faf 过滤后 GT 覆盖 97.9%、非 GT 航迹 −91%、10 次断裂归因（跟踪器自身 5 次 / 过滤致因 5 次，37 帧来自恰好撞 `TRACK_CONFIRMED_DELETE_THRESHOLD` 的 24 帧连续漏检）。
