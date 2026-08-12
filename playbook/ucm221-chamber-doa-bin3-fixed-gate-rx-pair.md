---
id: ucm221-chamber-doa-bin3-fixed-gate-rx-pair
type: bullet
status: validated
scope: project:ucm221
domain: radar-doa
tags:
- ucm221
- doa
- 暗室
- 距离门
- rx对
- eta校准
- 相位约定
triggers:
- UCM221 暗室数据测角，选距离门/峰值搜索
- 峰值搜索结果塌缩、六通道零相位（失败信号：被 bin0 DC 劫持）
- 用 Rx 对（Rx1/Rx2 方位、Rx4/Rx5 俯仰）做解耦测角
- 评估 Rx 对/稀疏阵测角能否达到工程精度
created: 2026-08-12
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: 人工（整理 inbox/capture-2026-07-29-03-16-43-941-afn6.md）
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related:
- episode-ucm221-uneven-array-doa
- ucm221-doa-reverify-fixed-gate-survives-bin0-hijack
---
# UCM221 暗室测角链路三结论：固定 bin3、y 向相位约定 -1、Rx 对解耦需 eta 校准

从零复现验证（2026-07-29）的三个可复用结论：

**①距离门必须固定 bin3**：Tx→Rx 泄漏 DC bin0 不随角度衰减，而目标能量按方向图滚降（0°→±50° 约 -25dB）；在俯仰 |el|≥35° 与水平 -55° 边缘，bin0 反超 bin3，峰值搜索会被 DC 劫持（bin0 六通道零相位 → 估计塌缩）。历史上"俯仰非线性混叠区"与此同源。

**②y 向硬件相位约定为 -1**：core 的 `elevation_phase_sign=-1` 与显示符号 -1 同源；Rx4-Rx5 基线实测相位 = π(u−v)。

**③Rx 对解耦测角可行但 eta 校准是必经步骤**：Rx 对解耦（Rx1/Rx2 方位、Rx4/Rx5 俯仰经 u 解耦）在干净数据上方位 MAE 3.0°、俯仰 4.8°，误差主因是角度相关相位偏差 eta（系统性 S 曲线）；全阵虚拟差分可压到 0.65°——证明 eta 校准（scheme B 路线）是 Rx 对/稀疏阵达到工程精度的必经步骤。

**反例/边界**：结论基于暗室干净数据；外场高杂波场景的边界见 related 复验条目。固定 bin3 的前提是目标落在 bin3 距离附近。

**证据**：capture-2026-07-29-03-16-43-941-afn6；实现 `ucm221 analysis/rx_pair_doa.py`（task/array-layout-doa-perf 分支）。
