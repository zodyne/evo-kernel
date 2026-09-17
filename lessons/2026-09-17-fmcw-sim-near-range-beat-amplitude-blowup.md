---
id: fmcw-sim-near-range-beat-amplitude-blowup
type: lesson
status: candidate
scope: global
domain: radar-sim
tags: [fmcw, radar-sim, near-range, amplitude, numerical]
triggers:
  - "FMCW/雷达时域仿真里目标靠近或穿过雷达（R0 很小）"
  - "仿真拍频/回波幅度异常爆表（比正常高几十上百 dB）却不出 NaN"
  - "给雷达仿真加近距保护 / 幅度钳位 / 最小距离截断"
  - "审查雷达仿真代码在小 R0 下的数值稳定性"
  - "仿真输出有限但数值大到失真（1e10 量级），怀疑距离几何项"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a43f-d297-763d-a251-9f1f9bbd931f
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [fmcw-absolute-phase-float64-precision]
---

FMCW 时域仿真的合成拍频幅度随距离几何项（1/R 的高次幂）放大：目标飞近/穿过雷达（R0 很小）时幅度会爆炸到比正常高约 190 dB，但仍是**有限值**（不是 NaN/Inf），不会抛异常，静默产生失真结果，因此必须加近距保护或幅度钳位。

为什么：实测对 2T8R BPM 仿真跑 `synth_beat`，正常目标 max|beat|≈5.56；当 R0=0.1 m、v0=−40 m/s（飞向雷达）时 max|beat|=1.935e+10，比正常高 190.8 dB，输出标「有限值=True」。距离项在 R→0 时发散，但浮点运算得到的是巨大的有限数，掩盖了问题。

反例/边界：幅度爆炸不代表计算崩溃——正是因为「有限且不报错」，这类飞穿场景的仿真结果会静默失真，难以被 assert 或肉眼发现，需要显式加最小距离截断或幅度上限并断言。
