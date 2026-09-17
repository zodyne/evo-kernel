---
id: bpm-pairing-needs-plus-minus-one-bin-tolerance
type: lesson
status: candidate
scope: global
domain: radar-bpm
tags: [bpm, mimo, doppler, cfar, pairing, tolerance]
triggers:
  - "BPM-MIMO 点云成对合并，两发鬼影峰多普勒序号差不是 Nc/2"
  - "实测两峰序号差 65 而非 64（失败信号）"
  - "CFAR 取整数 bin 极大，目标落在两 bin 之间导致 argmax 各掉一侧"
  - "同一目标在点云里出两个点"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-16-07-24-34-615-g5x4
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [bpm-folded-peak-pairing-needs-coherence-not-amplitude]
---

# BPM-MIMO 点云成对合并：多普勒序号差配对必须留 ±1 bin 容差

## 主张

BPM-MIMO 点云成对合并：两发鬼影峰的多普勒序号差理论上恰为 Nc/2，但 CFAR 取整数 bin 极大，目标落在两 bin 之间时两峰 argmax 各掉一侧（实测差 65 而非 64），配对必须留 ±1 bin 容差，否则同一目标出两个点（bpm_2t8r_sim T18 ⑤）。
