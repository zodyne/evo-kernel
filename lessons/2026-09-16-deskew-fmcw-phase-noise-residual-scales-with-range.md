---
id: deskew-fmcw-phase-noise-residual-scales-with-range
type: lesson
status: candidate
scope: global
domain: radar-signal
tags: [fmcw, deskew, phase-noise, cfar, impairment-modeling, range-doppler]
triggers:
  - "去斜 FMCW 相位噪声建模，逐 chirp 公共相位对 LO 与回波相消"
  - "相噪残差 ∝ τ，按 R/R_ref 缩放施加到每个目标"
  - "100 m 目标边带比 10 m 高约 20 dB（失败信号：强目标相噪裙边）"
  - "单级距离 CFAR 挡不住相噪裙边，要距离-再-多普勒两级 CFAR"
  - "多普勒保护窗该取多大（±4）"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-16-12-16-39-243-puin
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [fmcw-range-doppler-coupling-bias-moving-target, fmcw-coupling-correction-residual-with-folded-velocity]
---

# 去斜 FMCW 相位噪声建模：残差 ∝ τ，强目标相噪裙边要靠两级 CFAR 压

## 主张

去斜 FMCW 相位噪声建模：逐 chirp 公共相位对 LO 与回波相消，残差 ∝ τ（按 R/R_ref 缩放施加到每个目标），直漏(0.6 m)几乎无、100 m 目标边带比 10 m 高 ~20 dB；强目标相噪裙边要靠距离-再-多普勒两级 CFAR（多普勒保护窗 ±4）压，单级距离 CFAR 挡不住。

## 来源

bpm_2t8r_sim simulate.Impairments/T19。
