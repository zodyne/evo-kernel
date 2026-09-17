---
id: fmcw-range-doppler-coupling-bias-moving-target
type: lesson
status: candidate
scope: global
domain: signal-processing
tags: [fmcw, radar, range-doppler-coupling, simulation, dsp]
triggers:
  - "FMCW 仿真/处理里运动目标距离读数有系统偏置"
  - "拍频只按 2μR/c 算，漏了 2v/λ 项"
  - "距离-多普勒耦合导致距离偏 v·f0/μ"
  - "审查雷达仿真距离轴是否含耦合项（失败信号：距离随速度漂移）"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4ee-6d56-777c-a410-3236022192ef
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [fmcw-coupling-correction-residual-with-folded-velocity, deskew-fmcw-phase-noise-residual-scales-with-range]
---

# FMCW 距离-多普勒耦合：运动目标距离读数带 v·f0/μ 固定偏置

## 主张

FMCW 运动目标的拍频是 `2μR/c + 2v/λ`，不是 `2μR/c`。忽略耦合项会让运动目标距离读数带 `v·f0/μ` 的系统偏置（f0 = 载频，μ = 调频斜率），速度越高偏得越多。仿真/处理里要么在距离轴上补偿，要么至少写断言确认该偏置量级。

## 证据

- 实测：`f0/μ = 19.712 mm per (m/s)`，`v=55 时偏 1.0842 m = 1.45 bin`。
- `T16 [PASS] 运动目标的距离读数 = R + v·f0/μ（|误差| < 0.25 个距离 bin）`；静止目标无偏置（`v=+0.0: R̂= 89.9377` 与预测一致）。

## 边界

- 静止目标不受影响（v=0 时耦合项为 0），所以只在动目标场景暴露。
- 是否需补偿取决于距离分辨率与速度量级：ΔR 小时 1.45 bin 不可忽略。
