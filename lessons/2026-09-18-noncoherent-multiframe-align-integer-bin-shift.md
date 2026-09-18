---
id: noncoherent-multiframe-align-integer-bin-shift
type: lesson
status: candidate
scope: global
domain: radar-signal
tags: [fmcw, multiframe, noncoherent-integration, range-migration, keystone, rcm]
triggers:
  - "多帧非相干积累前要把帧间距离走动对齐，纠结要不要上 keystone/插值重采样"
  - "目标逐帧跨距离 bin，考虑整 bin 移位还是亚 bin 精对齐"
  - "帧间对齐代码里写了重采样/相位补偿，复杂度直奔 O(N log N)（失败信号：把相干处理的做法套到非相干积累）"
  - "评估距离走动补偿方案的复杂度与收益"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a7b1-a576-777c-a410-326c0e8fea05
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [cross-frame-range-gate-must-track-target, detection-probability-not-peak-floor-ratio]
---

# 多帧非相干积累的走动对齐只需整 bin 循环移位，不需要 keystone 重采样

## 一句话主张

多帧走**非相干**积累时，帧间距离走动对齐用整 bin 循环移位即可（`round((k−k0)·mig_bins)`，O(1) 操作）；
keystone/RCMC 那类重采样与相位补偿是**单个 CPI 内相干处理**才需要的，套到非相干积累上既无必要，又多付一次插值误差与计算量。

## 为什么

非相干积累只关心各帧包络/功率的相对位移，不保留帧间相位，因此不需要亚 bin 级相位精度的重采样；
整 bin 移位把主要的帧间位移对齐后，剩余亚 bin 失配是小量（具体数值随窗函数与口径变化，不宜跨项目直接引用）。
SAR 文献同样把 RCMC 归在相干的距离-多普勒域处理步骤里——本次核验下载的 UBC BISAR 论文正文可逐字查到
`Residual RCMC (box 7) is performed in the range Doppler …`。

## 反例 / 边界

- 若处理链是**相干**积累（保留相位、跨帧做相位对齐/补偿），亚 bin 重采样或相位补偿是必要的，本条不适用。
- 目标跨 bin 数远大于 1 bin/帧时整 bin 移位仍成立，但"残留亚 bin 失配可忽略"的前提要按损失曲线复核；高速 + 长帧周期下先算 nRCM 再决定。
- 本条依据是核验中读到的项目设计（README 对齐段）与文献原文，会话未做"整 bin 移位 vs keystone"的数值对照实验，故如实标 verified_by: human。

## 证据

命令 ↔ 结果（session 01a0a7b1 切片）：

- `sed -n '443,470p' README.md` →
  `⚠ 对齐**只需整 bin 循环移位**（round((k−k0)·mig_bins)，O(1) 操作）：多帧走的是**非相干**积累，它只关心帧间相对位移，不需要 keystone 那类**单个 CPI 内相干处理**的重采样/相…`
- `pdftotext ubc.out ubc.txt` + grep →
  `294:gate. Residual RCMC (box 7) is performed in the range Doppler`
- 同会话实算帧间走动（Hann 窗、v=−9.886 m/s）：`nRCM/frame = 0.5635898952467977`，即单帧位移不足 1 bin，与"整 bin 对齐主要位移"的前提一致。
