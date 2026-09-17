---
id: ddma-rd-map-sparse-grid-render-mask
type: lesson
status: candidate
scope: global
domain: visualization
tags: [ddma, rd-map, valid-mask, colormap, radar-display]
triggers:
  - "DDMA 展开 RD 图（range×n_chirp）出现成片结构性空白格"
  - "雷达热力图大片同色、看不出动态范围（失败信号）"
  - "MATLAB 式峰值归一 + 固定动态范围不适合稀疏格点图"
  - "用 valid mask 渲染 RGBA（无效格 alpha=0）+ 分位数自动定标"
  - "报告图该用折叠 RD 图还是展开 RD 图"
created: 2026-08-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-18-21-59-04-741-q6ld
last_verified: 2026-08-18
superseded_by: null
schema_version: 1
related: [nan-poisons-minmax-aggregation]
---

# 主张

雷达显示口径：DDMA 展开 RD 图（range×n_chirp）有 `(n_subband-1)/n_subband` 的格点**结构性为空**——每距离门只写 n_dop 列。再叠加 MATLAB 式峰值归一 + 固定动态范围，afm761 实测 83.7% RD 格点、99.9% 角谱格点落在同一底色。

# 对策

- 带 valid mask 渲染为 RGBA（无效格 alpha=0）；
- 按有效格分位数（p20, p99.9）自动定标；
- 报告图改用折叠 RD 图（全格有效）。

# 证据

见上（afm761 实测 83.7% / 99.9%）。
