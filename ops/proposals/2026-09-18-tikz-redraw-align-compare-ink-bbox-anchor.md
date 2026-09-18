---
id: tikz-redraw-align-compare-ink-bbox-anchor
type: lesson
status: candidate
scope: global
domain: latex
tags: [tikz, figure-reproduction, verification, pymupdf, ink-bbox]
triggers:
  - "逐像素比对重绘图与原图，曲线平均差几十像素且随位置增大"
  - "重绘图与原图整体错位/比例不对（失败信号）"
  - "两边像素坐标对不上，怀疑 DPI 或裁剪不一致"
  - "渲染回位图比对时曲线区域系统性错位（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae0f-e727-74bd-bb26-429f7e3cf7df
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [tikz-figure-reproduction-raster-diff-verification]
---

对齐锚点错 → 偏差量虚高：两侧坐标系不统一时，曲线比对出的平均差几十像素是假偏差。

为什么：本会话先按固定 offset（offx=-337, offy=+21.5）对齐，上曲线 mean=-41.65 rms=46.88 max|d|=106.70，疑似大幅失真；改用两边各自墨水 bbox 角做对齐锚点后，同样这组曲线 max|d|=1.5px —— 说明前面的「大偏差」是坐标系错位，不是绘制错误。

反例/边界：锚点本身必须是两边都清晰可定位的特征（本会话用墨水 bbox 角，ink_crop threshold 150/175 稳定一致）；固定 offset 或目测原点做锚点时，偏差量不可信。

证据：固定 offset 对齐跑出 mean=-41.65 rms=46.88 max|d|=106.70（含 worst 点 -104/-105px）→ 改墨水 bbox 对齐后同组曲线 max|d|=1.5px（两轮结果都在切片命令↔结果对里）。
