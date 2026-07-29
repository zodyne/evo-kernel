---
id: 2026-07-27-pyqtgraph-viewer-lag-is-perframe-python-compute
type: playbook
status: validated
scope: global
domain: performance-profiling
tags: [pyqtgraph, qt, pyqt, pyside, profiling, viewer, realtime]
triggers:
  - pyqtgraph / PyQt / PySide 实时查看器卡顿，第一反应怀疑 GL 渲染或 setData 慢
  - 实时点云/曲线查看器帧率上不去，想换渲染后端或降采样
  - 帧耗时拆解后 paintGL / setData 都很便宜，但"其余"占了大头不知道是什么
  - 每帧都重算的派生量（区间重建 / 聚合 tally / 特征）在拖帧
  - 想区分"渲染瓶颈"还是"每帧冗余计算瓶颈"但无从下手
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:c0a7ecbd-7117-4c93-931a-53aca42b7fed
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---

# pyqtgraph 查看器卡顿：先量渲染地板价，别急着怪 GL

pyqtgraph / Qt 实时查看器卡顿时，`paintGL` 和 `setData` 通常都很便宜（本例各 0.58 ms / 0.15 ms），帧耗时的大头是**每帧都重跑一遍的 Python 侧计算**（区间 span 重建、tally 聚合、特征计算）。诊断第一步：用「数据不变时的空转 repaint」测出**渲染地板价**（本例 0.02 ms/次），就能把"渲染慢"和"每帧冗余计算慢"一刀切开——地板价接近 0，说明渲染没问题，去 Python 侧找每帧热点。

## 为什么

直觉上"卡"=画面刷新慢=渲染（GL/绘图）慢，于是去换渲染后端、降采样、调 OpenGL 配置。但 pyqtgraph 的数据上传 `setData` 和绘制 `paintGL` 在中等数据量下是亚毫秒级；真正吃帧的是**每帧无脑重做的派生计算**——因为它们挂在刷新回调里，跟数据变没变无关，每帧都全量重算。本会话就是这条路径：拆帧后发现 `paintGL 0.58 + setData 0.15`，"其余 32.40 ms" 全是每帧 Python 侧重建；把这些计算改成按锚点增量/缓存后，单帧从 32.83 ms 降到 9.40 ms（约 3.5×）。

## 怎么量

1. **帧拆解**：在刷新回调里计时 `setData`、`paintGL` 与"其余"，看大头落在哪。
2. **渲染地板价**：触发一次数据完全不变的空转 repaint，记帧耗时——这就是纯缓冲交换/vsync 开销（本例 0.02 ms）。
3. **定位**：地板价 ≈ 0 且 paintGL/setData 都便宜 → 瓶颈在每帧 Python 计算；用 cProfile 锁定那个每帧都进的热函数，改成增量/缓存。

## 边界

- 数据量极大（百万点级）时 `setData` 本身会变贵，地板价法仍成立但结论可能反转——先量再下判断。
- 空转 repaint 若被 Qt 合并/跳过（数据不变时根本不重绘），测到的是"不做功"的成本，需确认它代表的是渲染开销而非"没渲染"。
- 优化方向是**诊断定位**：具体增量/缓存策略跟业务耦合（本例是"累积自锚点起算"），不属于本条主张。
