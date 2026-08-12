---
id: filter-relaxation-quantify-keep-increment
type: lesson
status: candidate
scope: project:ucm221
domain: filtering
tags: [ucm221, point-cloud, filter-tuning, specificity-cost, npy, keep-increment]
triggers:
  - "评估放宽过滤条件换召回的提议（改 persist/dop/门槛）"
  - "faf 参数调整前想量化会多放进多少杂波"
  - "凭直觉争论某个放宽条件值不值，没有数字"
  - "同一放宽条件在不同数据集上效果外推（失败信号）"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fbb55-aff3-7aa0-937b-51eaddbeab92
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [ucm221-marginal-points-support-track-continuity, npy-mmap-for-million-point-intermediate-data]
---
# 放宽过滤条件换召回前：用落盘点云统计 KEEP 规模增量百分比，拿数字做取舍

## 主张

评估任何"放宽过滤条件换召回"的提议（放行 MARGINAL 子集、persist 改并集、降 SNR/速度门限等），**先在已落盘的点云 .npy 上直接统计该条件会把多少点升级进 KEEP，用"KEEP 规模增量百分比"当特异性代价**再决定取舍。同一条件在不同数据集上代价可差数倍，不许跨数据集外推。

## 证据（直接在 out/<ds>/ 的 points_in.npy 上统计）

- 条件 `MARGINAL ∧ |v|≥1 ∧ snr≥12`：000028 上命中 624,285 点（32.76% of 输入）→ **KEEP 增量 188.5%**——召回没换来多少，点云先膨胀近两倍。
- 条件 `persist 并集 K 帧`：000028 上 KEEP 规模增量约 **73.0%**（帧均 16.09 点）；000034 上仅帧均 6.70 点、合计 10,823——同条件两代价值差出一个量级，单数据集结论不可外推。
- 纯空间宽容差(0.06/3m)：目标命中 82.4% vs 杂波命中 77.2%；加多普勒联合(±0.45 m/s)后杂波命中仅降到 76.9%——联合条件几乎不增加区分度，也是用落盘数字直接否掉一个直觉方案。

## 边界

- 增量百分比只量"特异性代价"，不量召回收益；收益侧要靠航迹连续性（如 GT 覆盖率）另行评估，两边数字齐了再拍板。
- 统计基于离线落盘点云；嵌入式实时路径的算力代价不在此口径内。
