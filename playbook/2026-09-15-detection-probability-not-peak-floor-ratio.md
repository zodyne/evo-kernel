---
id: detection-probability-not-peak-floor-ratio
type: lesson
status: validated
scope: global
domain: radar
tags: [radar, noncoherent-integration, pd, snr, metric, monte-carlo]
triggers:
  - "评估多帧非相干积累的增益/改善,决定用什么指标"
  - "想用峰值/噪声底比值来量化积累效果"
  - "核验「非相干积累不改善信噪比」类说法该测什么"
  - "峰/底比在积累前后几乎不变,被当成积累无效(失败信号)"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a5ef-b7d0-777c-a410-325dae81e5ed
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [noncoherent-sum-statistic-dof-2nk]
---

# 多帧非相干积累的收益指标是固定 P_fa 下的 P_d,不是峰值/噪声底比

## 主张
评估多帧非相干积累(Σ|X_k|²)的收益,指标用固定 P_fa 下的检测概率 P_d;不要用「峰值/噪声底」比值——它在均值意义上不变(信号 N·A²、噪声 N·σ² 同乘 N),且单次读数受 σ_底 波动影响大。

## 为什么
项目 SPEC 的结论与本次核验一致:峰/底均值比与 K 无关(评审蒙特卡洛证实恒为 ~2),但 P_d 随 K 显著上升——单脉冲 SNR 1.5 dB、P_fa=1e-3 下,K=1/2/4 → P_d = 0.4439 / 0.8257 / 0.9930(scipy chi2 闭式实算)。若拿峰/底比评估,会得出"积累无效"的错误结论;T11 打印的阈值/底也逐 K 不同,印证单次峰/底读数不是稳定判据。

## 边界 / 反例
- 峰/底比并非永远无意义:它是不变量,可用于检查积累实现有没有把信号/噪声缩放错(比值突然偏离 ~2 才可疑);但它不能作为"积累有没有用"的性能指标。
- P_d 数值依赖具体 SNR/P_fa/K 组合,引用时要连同口径一起给;闭式 P_d 的自由度口径见 `noncoherent-sum-statistic-dof-2nk`。

## 证据(2026-09-15 会话命令对照)
- 会话切片实跑 scipy 输出:`Pfa=1.00e-03 K=1 Pd=0.4439 K=2 Pd=0.8257 K=4 Pd=0.9930`(chi=1.4125,即 1.5 dB)。
- 项目 frames.py:268 与 SPEC_multiframe.md C5 节(grep 命中):非相干积累「均值意义上不改变峰值/噪声底比值(信号 N·A²、噪声 N·σ²)」;SPEC:151 记评审蒙特卡洛证实峰/底均值比恒定。
