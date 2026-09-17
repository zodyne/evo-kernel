---
id: cross-frame-range-gate-must-track-target
type: lesson
status: candidate
scope: global
domain: radar-signal
tags: [deambiguation, range-gate, cross-frame, frame-period, simulation]
triggers:
  - "多帧解模糊 / 跨帧积累时固定用选中帧的 i_r 去读其它帧"
  - "帧周期改成 50 ms 后高速目标跨距离 bin，读到噪声门（失败信号）"
  - "解模糊速度解成 51.45 而非 55.0"
  - "仿真帧周期与真实雷达不一致导致点云看不出运动"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-16-07-58-55-056-w626
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: []
---

# 多帧解模糊/跨帧积累的距离门必须跟着目标走

## 主张

多帧解模糊/跨帧积累的距离门必须跟着目标走：帧周期改成真实的 50 ms 后，55 m/s 目标一帧走 3.7 个距离 bin，固定用选中帧的 i_r 读其它帧读到的是噪声门（解成 51.45 而非 55.0）；在「搜索半窗速度×时间差」允许范围内取距离剖面最强门即可（bpm_2t8r_sim workbench._observations）。
