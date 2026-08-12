---
id: ucm221-marginal-points-support-track-continuity
type: fact
status: candidate
scope: project:ucm221
domain: tracking
tags: [ucm221, point-cloud, tracking, marginal, ab-test, false-alarm-filter]
triggers:
  - "UCM221 点云三级标签（KEEP/MARGINAL/REJECT）放行门槛调整"
  - "想收紧过滤只放 KEEP 点来降点云规模"
  - "过滤改完后航迹存活帧数骤降/航迹断裂"
  - "false_alarm_filter 放行策略做 A/B 仿真对比"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:40a7756a-b82e-42cf-9704-be6eafb35707
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [playbook-ucm221-cfar-point-cloud-filtering, episode-ucm221-project-overview]
---
# UCM221：MARGINAL 点对航迹连续性有实质支撑，只放 KEEP 会拉断航迹

## 主张

在 000028 数据集（15040 帧、190 万输入点）的嵌入式流水 A/B 仿真中，放行门槛从 KEEP+MARGINAL 收紧到只放 KEEP，点云规模从 52.0% 降到 11.9%，但参照目标航迹明显变差——**MARGINAL 点虽然 SNR 低，却给跟踪提供了关键的点支撑连续性**，不能只当噪声砍掉。

## 证据（000028 A/B，嵌入式 sim 真实产物 libSPX_ALG 跑出）

- 航迹 id=1 生命周期：`legacy 存活 146 帧（区间 1..146）`、`filter-only 存活 145 帧`，而 `keep-only 存活区间只剩 20..36`。
- keep-only 下该目标出现无点支撑帧：`[4, 6, 34, 36, 40, 78, 119, 130, 132, 137]`。
- 点云规模：legacy 输出 991,682 点（占输入 52.0%，每帧中位 70）；keep-only 输出 226,353 点（占 11.9%）。
- 14 条参照航迹位置上的最近输入点共 4538 个：KEEP 2528（55.7%，SNR 中位 31.8 dB）、MARGINAL 357（7.9%）——MARGINAL 占比小但恰好补在 KEEP 缺失的帧上。

## 边界

- 结论基于 000028 单数据集 + 现流程 false_alarm_filter 参数；门槛调整后结论可能变化，需重新 A/B。
- 本条说的是"航迹连续性"维度；MARGINAL 点同时会抬高虚警/算力开销，取舍取决于下游更看重哪个指标。
