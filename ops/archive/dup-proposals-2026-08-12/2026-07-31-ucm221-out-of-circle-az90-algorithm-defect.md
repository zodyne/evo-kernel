---
id: episode-ucm221-out-of-circle-az90-algorithm-defect
name: UCM221 出圆点（az 夹 ±90）根因：单源估计器无联合约束，非 FPGA 实现/校准错误
type: episode
status: candidate
scope: [debugging, signal-processing]
domains: [ucm221, radar, doa]
tags: [direction-cosine, fpga, offline-recompute, dual-source]
triggers:
  - "UCM221 点云出现 u²+v²>1 的出圆异常点"
  - "az 大量被夹到 ±90°，怀疑 FPGA 测角算错"
  - "FPGA 与离线算法结果不一致，要归因到实现、校准还是算法本身"
  - "给 UCM221 测角链路加出圆点过滤/修复之前"
  - "单源 DOA 估计在大角度/多源快拍下发散"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:7b0f5574-d7d5-40e9-9f05-3fdac54578e1
last_verified: 2026-07-31
superseded_by: null
schema_version: 1
related: [episode-ucm221-fpga-cache-mismatch, ucm221-leakage-far-exceeds-hann-sidelobe, ucm221-filter-direction-cosine-native]
---

# UCM221 出圆点根因归因：FPGA 忠实执行了算法，问题在输入与算法本身

## 主张

UCM221 点云中 az 被夹到 ±90° 的出圆点（u²+v²>1，约占 0.72%~2.76%）**不是 FPGA 实现错误，也不是通道校准缺失**；根因是单源 DOA 估计器无联合约束——出圆点 96.3% 需要双源模型才拟合得上（圆内对照组仅 52.9%），即快拍里实际含多个源，单源估计发散出单位圆。

## 证据（离线复算，命令+数值结果）

- 抽 7859 个出圆点用三套离线估计器复算对比（`offline_doa.py`/`offline_doa2.py`/`offline_doa3.py`，co-array FFT Rx1–4，原始/校准输入）；
- 以圆内对照组 γ_max p10 = 0.637 作单源门限判定：**FPGA 忠实复算 72.4%**，"忠实且快拍确含单源"仅 41.4% → 判定为算法缺陷（无联合约束）；
- 加通道校准后仍出圆 71.2%（对照组 0.2%）→ 排除校准因素；
- 出圆点 SNR 中位 23.4 dB，高于圆内对照组 16.7 dB → 不是低信噪比噪声点；
- persist 命中率：圆内 6.3% vs 出圆 3.9%。

## 可复用方法

FPGA vs 离线结果不一致时，先**忠实复算**（同一输入跑离线等价实现）区分"实现错"与"算法错"；归因判定的门限用**对照组统计分位数**（如圆内点 γ p10）而非拍脑袋阈值，避免把算法固有缺陷误当实现 bug 去改 FPGA。

## 边界

- 结论基于 000034 / 0709_2 等实采数据集的离线分析，未做固件侧修改验证；
- "双源才拟合得上"是以 γ₂src−γ₁src>0.15 判定的，门限选择影响具体比例，但 96.3% vs 52.9% 的量级差是稳的；
- 与 `episode-ucm221-fpga-cache-mismatch` 互补：那次根因是数据缓存未清空（输入错），这次是算法本身缺陷——归因前两类都要排除。
