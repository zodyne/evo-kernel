---
id: multi-zoom-views-report-same-metric-once
type: lesson
status: candidate
scope: global
domain: reporting
tags: [visualization, report, metric-consistency, matplotlib, panel]
triggers:
  - "报告/图表里同一对象有全景 + 放大两级视图（多 panel）"
  - "两级 panel 上同名指标（贴合点数 / 覆盖率 / 计数）数字对不上（失败信号）"
  - "给评审/汇报材料设计多尺度可视化"
  - "读者拿两个 panel 的数字互相质证『为什么不一样』"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:eaa269a8-34b2-4abf-a08f-1dd23a6ff138
last_verified: 2026-08-03
superseded_by: null
schema_version: 1
related: []
---

**主张**：同一对象的全景视图与放大视图并列时，**同一个指标只在一级报数**——全景 panel 只报总量级数字，需要贴合具体目标的指标只在放大级报。两级各报一次同名指标，统计窗口难免不同，数字对不上会直接损害汇报可信度。

**证据**（ucm221 faf_offline progress_plot.py，2026-08-03）：点云 3D 图分全景 / 放大两级 panel，最初两级都报「贴合目标点数」，全景级按全场景统计、放大级按局部窗口统计，同名指标两个数。补丁注释记录决策：「全景 panel 只报总点数；贴合目标只在放大级报，免得两级同名指标数字对不上」，改后重出图通过目检。

**做法**：设计多尺度 panel 时先给每个指标指定**唯一播报层级**：总量指标（总点数、总帧数）归全景级，目标级指标（贴合数、误差）归放大级；caption 里写清每个数字的统计窗口。

**边界**：若两级视图本就标注了不同的统计窗口/口径且读者预期会看到两数（如「全局覆盖率 vs 局部覆盖率」两个不同名指标），分别报数是对的——本条管的是**同名**指标在两级重复出现造成的自相矛盾。
