---
id: fmcw-absolute-phase-float64-precision
type: lesson
status: candidate
scope: global
domain: radar-sim
tags: [fmcw, radar-sim, float64, phase, numerical-precision, 77ghz]
triggers:
  - "FMCW/雷达仿真里绝对相位 2πf0·t 累积到 1e9 rad 量级（高频载波 × 长时宽）"
  - "测距/测速/测角结果在小数点后几位抖动、或与 golden 对不上，怀疑浮点相位精度"
  - "77GHz 高频雷达仿真里直接拿绝对相位做相干累积/参考"
  - "给雷达仿真做相位精度分析或数值稳定性审查"
  - "仿真相位对不上理论值，但公式推导没看出错（失败信号：想不通哪里丢精度）"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a3f4-bbd4-763d-a251-9f1065aa3a2a
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [fmcw-sim-near-range-beat-amplitude-blowup]
---

77GHz FMCW 仿真的绝对相位 2πf0·t 会累积到 ~3.7e9 rad（约 5.9 亿圈），float64 的相对精度 eps≈2.22e-16，使该绝对相位的**可表示精度下界约为 8.25e-7 rad**；因此测距/测速/测角必须走混频后的差频（相对相位），不能直接累积或依赖绝对相位。

为什么：实测对 2T8R BPM 仿真用 `eps=np.finfo(float).eps` 与 `bound=2πf0·T·eps` 计算，绝对相位 2πf0·t=3.716e9 rad，下界 =2π·f0·t·eps=8.250e-7 rad。相位一圈 2π≈6.28，8e-7 rad 对角度/速度的换算误差在高频下不可忽略。

反例/边界：这不是计算崩溃——float64 不报错，只是相位尾数精度被绝对量级吃掉；若只盯着「有没有 NaN」会漏判，需按量级估算精度下界并改用相对相位路径。
