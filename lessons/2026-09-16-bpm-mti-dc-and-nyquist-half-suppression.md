---
id: bpm-mti-dc-and-nyquist-half-suppression
type: lesson
status: candidate
scope: global
domain: radar-bpm
tags: [bpm, mti, clutter, nyquist, hann-window, false-alarm, weighted-mean]
triggers:
  - "BPM 静杂波抑制(MTI)后配对塌、虚警上升"
  - "静止回波同时占慢时间 f=0 与 Nyquist（TX1 码乘 (−1)^n）"
  - "减均值只留一半杂波（失败信号：虚警 +16）"
  - "均值没按多普勒窗加权，被 Hann 窗放大成 DC/Nyquist 假峰（虚警 +24）"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-16-12-16-39-209-s468
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [suc221-mti-mean-vs-frame-cancellation, suc221-static-clutter-notch-beats-mti]
---

# BPM 静杂波抑制(MTI)两条坑：DC/Nyquist 双占位与窗加权均值

## 主张

BPM 静杂波抑制(MTI)两条坑：①静止回波同时占慢时间 f=0 与 Nyquist（TX1 码乘 `(−1)^n`），只减均值留一半 → 配对塌、虚警 +16；②均值必须按多普勒窗加权（`Σw·x/Σw`），矩形均值减掉后被 Hann 窗放大成 DC/Nyquist 假峰（many 8 帧 +24 虚警）。

## 来源

bpm_2t8r_sim T19。
