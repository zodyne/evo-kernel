---
id: algommw-waveform-config-struct-location
type: fact
status: candidate
scope: project:algommw
domain: codebase-map
tags: [algommw, waveform, WaveCfg_t, adc_samples, doppler]
triggers:
  - "algommw 波形配置结构 WaveCfg_t 定义在哪"
  - "查 algommw 的 Tx/Rx 通道数、每 chirp ADC 采样数配置字段"
  - "移植 algommw range→doppler→cfar→doa 上游，找波形配置结构"
  - "找不到 WaveCfg_t 或波形配置字段定义位置"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0ad4f-eaf6-77c1-a593-51b2e084f190
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
---

algommw 的波形配置结构 `WaveCfg_t` 定义在 `core/include/core/types/waveform.h:34-43`，
字段含 `eModulation`、`ulNumTx`/`ulNumRx`（收发通道数）、`ulNumAdcSamples`（每 chirp 采样 = Range FFT 点数）、
`ulNumDoppler`（= Doppler FFT 点数）。

为什么：搬运 range→doppler→cfar→doa 上游前需先对齐波形配置语义，
此结构就是通道数与 FFT 点数的权威来源。

证据：本次侦察末条 assistant 给出 file:line 精确回答（未附独立命令输出，按 human 级验证）。
