---
id: ucm221-static-clutter-notch-beats-mti
type: bullet
status: validated
scope: project:ucm221
domain: radar-signal
tags: [ucm221, mti, cfar, 静杂波, 零多普勒陷波, 实测]
triggers:
  - "静止地面雷达数据做静杂波抑制方案选型"
  - "MTI 帧间对消后强地杂波残差仍超 CFAR 阈值"
  - "对消比达不到理论预期，怀疑实现 bug"
  - "静杂波能量集中在零多普勒附近几个 bin"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-03-07-13-42-628-d1hx
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [ucm221-mti-mean-vs-frame-cancellation, playbook-ucm221-cfar-point-cloud-filtering]
---
静止雷达场景下零多普勒陷波远优于 MTI 帧间复对消（UCM221 静止地面数据实测）。

**机理**：MTI 帧间复对消受帧间相位抖动限制——相干度 0.9995（相位 σ~0.03rad）对应对消比上限 ~29dB（实测 29.2dB，吻合）；强地杂波（超噪底 57dB）残差仍超 CFAR 阈值，抑制率仅 53–57% 且噪声地板抬升 3dB。同场景零多普勒陷波抑制 91.4% 且 100% 保留带外动点；静杂波能量集中 ±1 个多普勒 bin（0.11m/s）。

**结论**：静止雷达场景 陷波 >> MTI；MTI 的价值在运动雷达（杂波谱展宽），但需先解决帧间相干性。

**边界**：结论基于静止地面数据；运动平台杂波谱展宽后陷波会误伤慢目标，不能直接外推。
