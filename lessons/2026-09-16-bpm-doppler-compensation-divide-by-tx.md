---
id: bpm-doppler-compensation-divide-by-tx
type: lesson
status: candidate
scope: global
domain: radar-dsp
tags: [bpm, tdm-mimo, 多普勒, 相位补偿, doppler, 解调, tx]
triggers:
  - "给 BPM/TDM-MIMO 波形写/审 Doppler 相位补偿（demodulation）"
  - "多 Tx 波束测角角度系统性偏差，怀疑相位补偿系数差一个整数倍"
  - "lane 间 chirp 间隔与多普勒采样间隔不一致时的相位换算"
  - "复用单 Tx 波束的 Doppler 补偿代码到多 Tx 波束"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7da-1c77-7719-ba82-31e9d9d40735
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [bpm-folded-peak-pairing-needs-coherence-not-amplitude, doa-0deg-corner-unconstraining-cross-beam-consistency]
---

BPM/TDM-MIMO 解调的 Doppler 相位补偿因子要除以 Tx 数：lane0/lane1 相隔 1 个 chirp（时间 T），而多普勒采样间隔是 2T，所以相位系数是 π 而非 2π（2Tx 下即 π·d/NC）。漏除 Tx 会把补偿相位放大一倍。

实测：修正前用 2π 系数、修正为 π 后，解调快拍与理想导向矢量最大偏差降到 1.24e-16，并有反证测试 `test_bpm_compensation_without_the_tx_factor_would_fail` 锁定该口径（漏除 Tx 必挂）。
