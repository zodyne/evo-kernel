---
id: radar-workbench-layout-one-card-one-question
type: lesson
status: validated
scope: global
domain: visualization
tags: [radar, workbench, layout, point-cloud, ui-design, frame-period]
triggers:
  - "搭雷达工作台/点云可视化面板，决定主面板放什么"
  - "每张卡该答几个问题、深挖面板怎么收"
  - "目标表按点云还是按 CFAR 单元列行"
  - "仿真采集帧周期给多长（真实雷达 50–100 ms）"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-09-16-07-58-55-094-fglq
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: []
---

# 雷达工作台布局：点云做主面板、每张卡只答一个问题、帧周期按真实雷达给

## 主张

雷达工作台布局：点云（极坐标地面：距离弧+方位射线+FOV，当前帧/历史/真值三层）做主面板，每张卡只答一个问题，深挖面板（剖面/时域/解模糊）收进 tab，目标表给点云（每目标一行）而不是 CFAR 单元（每目标两行）。

## 边界

仿真采集的帧周期要按真实雷达 50–100 ms 给，否则 40 帧只有 0.3 s、点云看不出运动（bpm_2t8r_sim 2026-09-16 重排）。
