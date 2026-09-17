---
id: mimo-channel-order-phase-diff-exhaustive-search
type: lesson
status: candidate
scope: global
domain: radar-doa
tags: [mimo, channel-order, phase-difference, geometry, exhaustive-search, calibration]
triggers:
  - "MIMO 雷达查几何 / 通道序（TX/RX 排序）"
  - "需要不依赖真值、也不依赖逐通道标定的几何判据"
  - "用两个干净格子的相位差消掉逐通道标定，只剩几何"
  - "穷举 8!=40320 种 TX/RX 排序打分验证通道序"
  - "差分对角度差 Δu 小的目标对不敏感，判据失效（失败信号）"
created: 2026-08-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-20-03-57-27-639-1jcf
last_verified: 2026-08-20
superseded_by: null
schema_version: 1
related: [doa-0deg-corner-unconstraining-cross-beam-consistency, known-angle-holdout-validates-doa-geometry, per-channel-phase-calibration-not-power-cycle-stable]
---

# 主张

MIMO 雷达查几何/通道序：用**两个干净格子的相位差**（消掉逐通道标定，只剩几何）做判据，可穷举 `8!=40320` 种 TX/RX 排序打分。

# 效果

d8t8r 上图纸顺序两侧都排第 1（TX 99.26% vs 均值 86%），一次性把「排布 / TX↔子带映射 / 通道序」全部证伪掉。

# 边界

差分对**角度差 Δu 小的目标对不敏感**，要挑 Δu 大的对。

# 证据

见上（d8t8r，TX 99.26% vs 均值 86%）。
