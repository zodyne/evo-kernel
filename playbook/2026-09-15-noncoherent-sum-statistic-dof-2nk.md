---
id: noncoherent-sum-statistic-dof-2nk
type: lesson
status: validated
scope: global
domain: radar
tags: [radar, noncoherent-integration, chi2, ncx2, dof, threshold, detection]
triggers:
  - "给多帧非相干积累写/核检测阈值与 P_d 的闭式表"
  - "核验简报/文档里的理论阈值或 P_d,与仿真实测打印对不上"
  - "多通道求和的检测统计量,想拿单通道 χ² 表直接套用"
  - "用 chi2/ncx2 算 P_d,不确定自由度该填 2K 还是 2·n_rx·K"
  - "阈值/P_d 表能对上一份文献却对不上项目仿真值(失败信号)"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a5ef-b7d0-777c-a410-325dae81e5ed
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored, detection-probability-not-peak-floor-ratio]
---

# 非相干求和统计量的自由度是 2·n_rx·K,不是文献单通道公式的 2K

## 主张
核验非相干积累的阈值/P_d 闭式表时,自由度必须与**本项目检测统计量的定义**匹配:8 个 RX 非相干求和、再对 K 帧取均值的统计量,dof = 2·n_rx·K = 16K;文献单通道公式(每帧 1 个复采样,dof=2K)给出的阈值/P_d 表数值整体不可用——先读统计量实现(如 `_cell_power` 对 8 RX 求和),再选闭式。

## 为什么
本项目 T11 实打印的 阈值/底 = 2.4359 / 1.9821 / 1.6325(K=1/2/4),而 2K 口径的 chi2.isf(Pfa=1e-3, 2K) 给 6.9078 / 9.2334(K=1/2),差 3 倍以上——极易误判成"仿真有 bug"。实跑 scipy(chi2/ncx2 + brentq 反解)按 16K dof 复算,才与 T11 打印一致。差异来源是统计量定义不同,不是数值错误。

## 边界 / 反例
- 若统计量确实是单通道每帧单复采样(2K dof),单通道公式没有问题;判据是代码里统计量对哪些维度求和/平均。
- "K 帧取均值"不改变 dof 的 16K 结论(均值是 16K dof χ² 的缩放),但缩放会影响阈值绝对值,闭式求解时要用同一缩放。
- 与 `dual-impl-cross-check-tolerance-grid-anchored` 互补:那条讲"对不上时用不共因对照实现定位";本条讲"对不上先查两边统计量口径是否同一定义",应先走本条再怀疑实现。

## 证据(2026-09-15 会话命令对照)
- 会话切片实跑:`Pfa=1e-3, 2K dof: K=1 V=6.9078 / K=2 V=9.2334`(chi2.isf)与 T11 打印 `阈值/底 = 2.4359 / 1.9821 / 1.6325` 对照,量级不符。
- 按 16K dof 复算(含 ncx2 非中心、brentq 反解)后与 T11 打印逐位对上(切片内多组命令输出)。
