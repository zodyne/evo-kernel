---
id: ucm221-filter-direction-cosine-native
type: fact
status: candidate
scope: project:ucm221
domain: signal-processing
tags: [ucm221, false-alarm-filter, direction-cosine, doa, point-cloud]
triggers:
  - "问 UCM221 过滤算法是否按角度（az/el 度数）做限制"
  - "在 false_alarm_filter.py / faf_c 里找角度阈值找不到（失败信号，不代表缺失）"
  - "给 UCM221 点云过滤加方位/俯仰角门限"
  - "理解 UCM221 测角输出是方向余弦 (u,v) 还是角度"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:253e3346-4c15-4372-829d-5360cbe67d66
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [playbook-ucm221-cfar-point-cloud-filtering, ucm221-marginal-points-support-track-continuity]
---
# UCM221 过滤链路以方向余弦 (u,v) 为原生量，逐点不做角度换算

## 主张

UCM221 点云过滤链路（false_alarm_filter.py / faf_c）**全链路以方向余弦 (u,v) 为原生量，逐点不做角度换算**；过滤条件若有空间限制，表达形式是 u/v 域阈值而非角度（az/el 度数）阈值。回答"过滤是否做了角度限制"或在代码里搜 angle/角度 找不到阈值时，应去查 u/v 域的过滤条件，而不是断言"没有角度限制"或"漏了"。

## 证据

- `grep -n -i "angle\|角度\|theta\|azimuth\|elev" python/lib/false_alarm_filter.py`：命中点只有 `_uv_to_angles`（120 行，u/v→角度换算工具函数）、`np.angle(xc[:, :4])`（141 行，取复数相位，非空间角）、`_uv_to_ang`（230 行）——过滤主路径无角度阈值。
- `faf_c.py` 37 行注释明文：「不是弧度角。全链路以方向余弦为原生量，**逐点不做角度换算**；凡是按角度表达的…」（154 行的 `angle(xc[k])` 同样是通道相位解缠绕，非空间角）。

## 边界

- 该结论只覆盖过滤链路的角度表达；测角/DOA 算法内部（相位差、解模糊）当然涉及相位"角"，与空间角度门限是两回事。
- 显示层/报告层若需要角度，由 `_uv_to_angles` 类工具函数在出口处换算，不影响链路内部表示。
