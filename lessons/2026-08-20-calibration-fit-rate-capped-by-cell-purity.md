---
id: calibration-fit-rate-capped-by-cell-purity
type: lesson
status: candidate
scope: global
domain: radar-calibration
tags: [自标定, 拟合率, 单目标纯度, 旁瓣, PSL, d8t8r]
triggers:
  - 用留出格子的平面波拟合率判断自标定好坏
  - 拟合率提升但谱峰/旁瓣没变化，怀疑标定没有真正变好
  - 想拿拟合度当标定残差读（失败信号）
  - 静止外场一个 RD 格子横跨整个视场、多散射体污染单目标纯度
  - 标定指标与运行指标（谱峰/旁瓣）给出相反结论
created: 2026-08-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-20-03-57-27-679-dwl8
last_verified: 2026-08-20
superseded_by: null
schema_version: 1
related: [calibration-set-not-validation-set]
---

# 自标定的「留出格子平面波拟合率」会被该格子自身的单目标纯度封顶，不能当标定残差读

自标定的'留出格子平面波拟合率'会被该格子自身的单目标纯度封顶，不能当标定残差读。

## 为什么（实测）

d8t8r 实测：标定后拟合度与 8x8 矩阵秩1占比相关系数 0.80、比值稳定 0.78±0.07。静止外场一个 RD 格子横跨整个视场必然多散射体。

## 判据

判断标定好坏要用运行指标（谱峰/旁瓣），不要用拟合率——两者在 d8t8r 上给出相反结论（拟合率 77%→88% 但 PSL 22.4→22.7 dB 无变化）。
