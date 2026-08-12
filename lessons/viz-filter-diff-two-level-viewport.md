---
id: viz-filter-diff-two-level-viewport
type: lesson
status: candidate
scope: global
domain: data-viz
tags: [visualization, radar, pointcloud, ab-comparison]
triggers:
  - "可视化过滤/裁剪效果看不出差别"
  - "以目标为中心开窗对比两组点云"
  - "对照图两组数据几乎一样"
  - "做算法效果汇报图"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:eaa269a8
last_verified: 2026-08-03
superseded_by: null
schema_version: 1
---

**主张**：展示过滤/裁剪类算法效果前，先查数据的空间分布再选视窗；若杂波不在目标身边，「以 GT 轨迹为中心开窗」永远看不到差别，应改用「全景 + 目标放大」两级视窗——全景呈现差异所在，放大窗证明目标本身无损。

**为什么**：实测案例中目标 id18 生命期内，两组输出点要么距目标 3 m 以内、要么在 40 m 以外，中间是空的；贴着轨迹裁窗两组点数几乎一样（624 vs 626），而全景下 legacy 28 820 点 vs faf 5 394 点，差异全在视场杂波上。开窗方式选错会把「有效」画成「无效」。

**边界**：两级视窗上下行须同一批数据、同视角同轴范围，否则疏密不可比；适用于「作用对象与受影响对象空间分离」的场景（过滤、降噪、掩膜）。

**证据**：ucm221-pointcloud-2.0 进展报告制作会话（2026-08-03），先按目标中心开窗得到假阴性，查数据分布后改两级视窗才呈现真实收益。
