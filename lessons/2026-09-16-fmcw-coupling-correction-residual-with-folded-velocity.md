---
id: fmcw-coupling-correction-residual-with-folded-velocity
type: lesson
status: candidate
scope: global
domain: radar-signal
tags: [fmcw, range-doppler-coupling, velocity-folding, rmse, deambiguation]
triggers:
  - "用单帧折叠速度做 FMCW 距离-多普勒耦合校正 R=R̂−v·f0/μ"
  - "|v|>v_max 时测距残差恒为 2·v_max·f0/μ"
  - "想用耦合校正把测距 RMSE 从 0.18 压到 0.006 m"
  - "速度模糊窗外必须先解模糊再谈测距精度（失败信号：残差恒为常数）"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-16-07-24-34-650-9rl3
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [fmcw-range-doppler-coupling-bias-moving-target]
---

# FMCW 距离-多普勒耦合校正：用单帧折叠速度时窗外残差恒为 2·v_max·f0/μ

## 主张

FMCW 距离-多普勒耦合校正 `R=R̂−v·f0/μ` 若用单帧折叠速度，`|v|>v_max` 时残差恒为 `2·v_max·f0/μ`（77G/200M/Tc=60µs 下 0.64 m/折叠周期）；窗内可把测距 RMSE 从 0.18 压到 0.006 m，窗外需先解模糊（bpm_2t8r_sim §9.5）。
