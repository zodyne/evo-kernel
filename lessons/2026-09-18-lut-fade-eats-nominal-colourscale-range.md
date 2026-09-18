---
id: lut-fade-eats-nominal-colourscale-range
type: lesson
status: candidate
scope: global
domain: visualization
tags: [colormap, lut, fade, dynamic-range, radar-display, matplotlib]
triggers:
  - "雷达幅值热力图色标的底部有 fade/渐隐到背景色的一段，想知道它吃掉多少量程"
  - "代码/图注声称动态范围 D dB（如 vmin=-45,vmax=0），图上却大片同一底色（失败信号）"
  - "审查色标利用率：量像素落在 [vmin,vmax] 内、落在渐隐区内的比例"
  - "给幅值图设 vmin/vmax 或解释『色标为什么没铺满』"
  - "对比两张图的动态范围声明，怀疑口径里混了渐隐段"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d2-d6ba-777c-a410-327560871932
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [ddma-rd-map-sparse-grid-render-mask]
---

## 主张

色标 LUT 底部的 fade 渐隐段按**标称满量程的比例**扣除，不是按数据分布扣除：`fade=0.30` 时，`vmin..vmax` 里真正可辨的范围只有 `(1-0.30)·(vmax-vmin)`，可辨下界 = `vmin + fade·(vmax-vmin)`。因此「vmin=-45, vmax=0 的动态范围是 45 dB」这句话在图上要打 7 折——实测可辨范围只有 31.5 dB（= -45 + 0.30×45）。

## 为什么

`bpm_2t8r_sim/theme.py` 的 `map_lut(n=256, fade=0.30)` / `mpl_cmap(mode="map", n=256, fade=0.30)` 把 turbo 底部 `fade` 比例渐隐到卡片底色（雷达幅值图专用）。渐隐是按 LUT 索引做的，而索引线性映射到 `vmin..vmax`，所以渐隐起点与数据无关地固定在 `vmin + 0.30·(vmax-vmin)`：vmin=-45 时正好是 -31.5，切片里审查脚本用的「渐隐区起点 -31.5」与此吻合。

审查静态图色标时会误读：底噪/背景本来就在渐隐段里，图上看起来「一片底色」不一定说明数据没结构，也可能是这一段的对比度被固化了。判断色标是否真用满，必须分别量两个比例：低于 vmin（被钳到纯底色）的像素比例，与落在渐隐段内的像素比例。

## 反例 / 边界

- 本条管「标称动态范围 vs 实际可辨范围」的口径差，与 `ddma-rd-map-sparse-grid-render-mask` 管的问题不同：那条是稀疏格点结构性空白 + 固定动态范围导致大片同色（对策是 valid mask + 分位数自动定标）；本条即使在密集格点、归一化正确时也成立，是 LUT 设计自带的口径损耗。
- 渐隐是有意的视觉设计（把背景压到底色），不是 bug；要写进结论的是「可辨范围只有 0.7D」，不是「色标坏了」。
- 若 fade 改成按数据分位定标或改为 0，本条不适用。

## 证据

session 01a0a7d2 的核验切片（脚本 `/tmp/vf/v9_cmap.py`、`/tmp/vf/v14_last.py`，均为审查者在 /tmp 独立复跑）：

- `fig2(a) vmin=-45 vmax=0: 数据 dB 分位 1/10/50/90/99/100 = [-53.76, -51.65, -49.42, -47.48, -46.03, 0.0] min=-58.37`
- `fig2(a) vmin=-45: 像素低于 vmin 的比例 = 0.9982（全部被钳到卡片底色）; 低于 -31.5(渐隐区起点) 的比例 = 0.9993 即：色标 45 dB 里实际用到的只有 31.5 dB`
