---
id: episode-ucm221-faf-legacy-gate-domain-bugs
type: episode
status: candidate
scope: project:ucm221
domain: signal-processing
tags: [ucm221, false-alarm-filter, direction-cosine, elevation-gate, dead-code, embedded-port]
triggers:
  - "给 UCM221 FAF 调方位/俯仰门限或改 v 域限制"
  - "faf 去掉 v < sin30(0.5) 限制、按新参数重跑 gt 评估"
  - "legacy 过滤代码里门限直接和 elevation（弧度）比较——作用在错误的量上（失败信号）"
  - "移植 legacy 过滤算法时发现某门限是从未生效的死代码"
  - "方向余弦 (u,v) 链路里要加角度门限，先 sin 变换到同一域再比"
created: 2026-08-02
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:7c4809cc-6484-46a8-ad6b-dc591541577a
last_verified: 2026-08-02
superseded_by: null
schema_version: 1
related: [ucm221-filter-direction-cosine-native]
---
# UCM221 FAF 移植发现两个门限 bug：俯仰门限比错量（弧度 vs sin）、方位门限是死代码

## 事件

faf 接入/移植过程中发现 legacy 过滤链两个静默门限 bug，已在接入时修正（embedded/MIGRATION.md:109、port/SPEC.md:44 有记录）；本次会话又按用户要求移除 v 域的 `v < sin30`（0.5）限制并重跑评估更新报告：

1. **俯仰门限作用在错误的量上**：legacy 把俯仰门限直接和 `elevation`（弧度）比；正确做法是把边界经 sin 变换后与 v 比（方向余弦域同域比较），即与 `-sin(边界)` 比。
2. **方位门限是从未生效的死代码**。
3. **v 域限制移除**：`signalProcessing.tcm893.c` 的 `SP_PIPE_FAF` 分支 v 上下限放开（706-711 行 `v_upper = 1.0f; ...`），重编重测。

## 证据

- 首条 user 指令："faf不限制v 小于sin30，重新加载数据并且使用新参数重新更新 gt_report.pdf"。
- grep 命中修正记录：MIGRATION.md:109 `| 俯仰门限 | 与 elevation 直接比 → 与 -sin(边界) 比 | 原先按弧度`；SPEC.md:44 `一段从未生效的死代码；俯仰门限则作用在错误的量上。两者已在接入时一并修正`；faf_offline/README.md `方位门限为死代码、俯仰门限作用在错误的量上、输出换算 asin(sin u/cos v)`。
- 效果可量化：make 重编成功后，同一数据 000028 上 `gt_eval.py` 的 faf 航迹条目 17588 → 23523，id 1 覆盖 99.7% → 100.0%、断 2 次 → 0 次、误差 0.18 m → 0.12 m。
- 门限域换算口径有 python 验证：`degrees(arcsin(-sin(elevation_rad)))` 换算后统计 `|el|>30` 的点 11950/63953；`scheme_fov.py` 给出 FOV 裁剪分解（000028 被砍 19.1%：俯仰 43395 / 方位 20501 / 夹缝 6226）。

## 可复用经验

- 方向余弦 (u,v) 原生链路里加任何"角度门限"，**先把边界 sin 变换到 u/v 域再比**；直接和弧度 elevation 比 = 门限作用在错误的量上，不报错、静默错。
- 移植 legacy 过滤代码时逐个门限验证"是否真的生效、是否比对量"——死门限与错域门限都不会报警，只能靠对账/覆盖类指标暴露。
