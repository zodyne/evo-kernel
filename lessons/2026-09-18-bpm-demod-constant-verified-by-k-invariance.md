---
id: bpm-demod-constant-verified-by-k-invariance
type: lesson
status: candidate
scope: global
domain: radar-dsp
tags: [bpm, tdm-mimo, doppler, 解调, 相位补偿, 实测核验]
triggers:
  - "在实测采集上判定/复核 BPM 多 Tx 波束的多普勒解调相位常数（α / Tx 补偿因子）"
  - "跨 lane（跨 Rx）相位随多普勒 bin 序号 k 线性漂移、或测角随速度变化（失败信号）"
  - "手上只有单元测试/仿真结论，要在真实硬件数据上给解调常数定案"
  - "静止 / 0° 角反数据对所有候选解调常数给出完全相同的结果（失败信号：判据无区分度）"
  - "给多 Tx 解调常数设计不依赖真值的验收判据"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ef-b8f1-777c-a410-327bb9fe35ad
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [bpm-doppler-compensation-divide-by-tx]
---

# 判定 BPM 多 Tx 解调常数：用真实通道的 k-不变性，别用静态数据

## 主张

在真实采集上判定 BPM 远波束的多普勒解调相位常数（2Tx 即 α=0.5，补偿相位除以 Tx 数）有一条不依赖真值的判据：**同一目标在不同多普勒 bin 序号 k 下，跨 lane（Rx 间）相位必须恒定**——把 inter-lane 相位对 k 做线性拟合，真值常数下斜率 ≈ 0、离散度 ≈ 0；常数偏整数倍时相位随 k 线性漂移。静态/k=0 的 0° 角反数据在原理上定不了这个常数（所有候选 α 结果完全相同），必须用非零多普勒的观测样本。

## 为什么

解调常数的误差直接乘在 k 上，等价于给每个 lane 加一个 ∝k 的相位斜坡：k 越大偏得越多，表现为"跨 lane 相位随速度漂移"，下游就是测角随目标速度变化。于是"常数对不对"被化归成一条可直接测量的曲线形状判据，既不需要角度真值、也不需要角反。

## 做法（本次实测口径）

拿真实通道数据当载体、注入合成多普勒相位扫 k（开环 HIL），对每个候选 α 算两个互相独立的指标：8 元虚拟阵相干度 ρ 与 lane 平衡度（imbalance dB），再对多帧投票取众数。

## 证据（session 01a0a7ef 切片，命令 ↔ 结果）

- 真实硬件 k-不变性（`SPC865_100M_OK_2026-06-09-11-24-34_0.bin` f1，远波束 bin22 R=34.93 m，目标 az≈5.8°）：
  `alpha=0.0: MODEL slope=+1.032 deg/bin  spread= 50.1 deg` vs `alpha=0.5: MODEL slope=-0.000 deg/bin  spread=  0.0 deg`
  → 常数取错（0.0）时跨 lane 相位随 k 漂 1.03°/bin、离散 50°；取 α=0.5 时斜率与离散度同时归零。
  同一脚本首行的口径说明：`k-invariance test on real channels (100M OK, bin22, R=34.93 m, target az~5.8deg) inter-lane phase arg(lane2/lane1) in ...`。
- 多帧投票（k=+16）：`OK k=+16 n=20: rho-votes {0.5: 20} | balance-votes {0.5: 16, 1.0: 4}`；单帧四候选的相干度 `rho={0.0: 0.561, 0.5: 0.641, 1.0: 0.556, 2.0: 0.408}`（α=0.5 居首）。
- 反例（判据无区分度）——暗箱静态 0° 角反 `865_0801_2025-10-09-11-40-04_0.bin` f1 bin3 R=3.33 m：`k=0: rho=0.9598 az=+0.25  (all alpha identical ...)`，即 k=0 时所有 α 给出同一结果。
- 最终报告把该判据列为定案节：`python3 final_report.py` 输出含 `[6] hardware-in-the-loop: k-invariance of ...`（`[1] container parse (their conventions)` 同属实测口径）。

## 边界 / 反例

- 必须有非零多普勒的样本；静止目标/k=0 数据对 α 完全退化。
- 单指标会误判：本次 balance 投票有 4/20 帧投给 1.0，而 ρ 投票 20/20 全票给 0.5。两指标冲突时以 8 元虚拟阵相干度 ρ 为主，lane 平衡度只作旁证。
- 本条是"怎么在实测上把常数钉死"的判据；常数本身的取值口径（除以 Tx 数，漏除会放大一倍）见 related `bpm-doppler-compensation-divide-by-tx`，不是同一条主张。
