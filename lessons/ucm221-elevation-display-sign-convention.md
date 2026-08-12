---
id: ucm221-elevation-display-sign-convention
type: lesson
status: candidate
scope: project:ucm221
domain: radar-doa
tags: [俯仰角, 符号约定, robust-doa, 对拍]
triggers:
  - "对比 UCM221 robust 链俯仰估计与真值/参考实现"
  - "俯仰真值 -45° 的估计显示成 +38° 上下，表面误差近 90°（失败信号）"
  - "给报告/图表算俯仰误差前没核对显示符号约定"
  - "rx_pair_doa.py 与 core/ 参考链俯仰结果符号相反"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:583c96aa-69cd-41b3-926b-4f72d4d7c7f5
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [episode-ucm221-uneven-array-doa, dual-impl-cross-check-tolerance-grid-anchored]
---

UCM221 robust 链俯仰角有**显示符号约定**（`rx_pair_doa.py:86` 的 `ROBUST_EL_DISPLAY_SIGN = -1`，对应 core 参考链 `--elevation-display-sign` 默认 -1）。不核对就直接与真值比较，会算出假误差。

会话证据：truth=-45° 的点 disp_el=+38.8°，表面 err=88.8°——这是符号/坐标约定假象，不是估计器崩了 88°（注意即使统一符号后大角度俯仰仍有真实偏差，est_u=0.894 / u_deg=63.4，两件事别混）。

教训：跨链对比、写报告误差表之前，先统一俯仰显示符号约定；见到"误差≈2×|truth|"的模式先怀疑符号，再怀疑算法。
