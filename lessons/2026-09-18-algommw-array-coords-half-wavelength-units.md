---
id: algommw-array-coords-half-wavelength-units
type: fact
status: candidate
scope: project:algommw
domain: codebase-map
tags: [algommw, 阵列坐标, 半波长, xPosX, 阵面]
triggers:
  - "algommw 阵元坐标 xPosX/xPosZ 的单位是什么"
  - "移植 algommw 阵列配置，坐标量纲要换算成米还是波长（失败信号：单位错导致测角全错）"
  - "读 algommw 阵面几何代码，x 方向对应方位还是俯仰"
  - "1D/2D 分流的 λ/8 极差判据要套坐标单位"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af3a-ab1b-7097-91f3-80f1eaca1bbd
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [algommw-doa-beam-1d2d-auto-split]
---

algommw 阵元坐标约定：`xPosX`/`xPosZ` 为每虚拟天线在阵面上的位置，
**单位是半波长（λ/2）**，x 维 = 方位（源码注释原文
「xPosX/xPosZ:每虚拟天线在阵面上的位置,单位半波长(λ/2)。x=方位」，
rg 命中于 core/include/core/base/types.h:16 附近注释块）。

为什么：这是阵列几何与测角换算的量纲锚。
beam 1D 分流判据「xPosZ 极差 < λ/8」直接建立在该单位上
（λ/8 = 0.25 个坐标单位）；换算成米或波长会导致极差判据与导向矢量全部错档，
且属静默错误、无报错。

边界：z 维对应俯仰的完整表述被切片输出截断，需要时读 types.h 原注释；
与 SUC221 MATLAB 侧的阵列坐标约定（d=λ/2 设计表）同源但仓库不同，勿混用文件。
证据：会话切片 rg 命令 `rg "typedef str…" core/include/core/base/types.h` 输出中注释行。
