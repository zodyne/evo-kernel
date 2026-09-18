---
id: lesson-2026-09-18-frame-scrub-bounded-cache-plus-live-edge
type: lesson
status: candidate
scope: global
domain: ui-design
tags: [radar-viz, frame-scrub, pyside, workbench, playback]
triggers:
  - "给雷达/信号回放工作台设计帧回看交互（逐帧前后走 / 时间轴拖拽 / 回实时）"
  - "回看历史要不要无限保存——内存随运行时长线性涨怎么办"
  - "拖完时间轴界面停在历史帧、没有一键回实时（失败信号）"
  - "决定帧缓存容量上限（_CACHE_FRAMES 类参数给多大）"
  - "参考 radar_viz 工作台决定自己的可视化要不要做回放"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae1d-bd62-77c1-a593-51bbbb5f695c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [radar-workbench-layout-one-card-one-question, 2026-07-27-pyqtgraph-viewer-lag-is-perframe-python-compute]
---

帧回看类工作台的控制成本模式 = 定长帧缓存 + 时间轴拖拽 + 显式「回到实时边缘」；radar_viz 工作台正是这样落地：缓存上限 `_CACHE_FRAMES = 2000`（`ui/workbench.py:57`），交互三件套（⏮⏭ 前后帧、时间轴可拖拽、⟲ 回到实时边缘）写在其自述注释（`ui/workbench.py:16`）。

**为什么**：有界缓存把回看内存从「随运行时长无限涨」封顶为常数（2000 帧）；⟲「回到实时边缘」补上「历史浏览态 → 实时态」的状态回归——拖拽时间轴后用户有明确出口，不会停在历史里。两条合起来，回看功能才敢开在常驻工作台里。

**反例/边界**：2000 帧是经验上限，更早的历史不在缓存内，不保证覆盖所有回看需求；切片只证明了「有界」与交互三件套的存在，缓存替换策略（环形/截断）未取证，不得过度断言为环形缓冲。这是 UI 交互结构事实，不涉及逐帧计算成本（后者见 related 的 pyqtgraph 每帧计算条目）。

**证据**：slice 命令↔结果第 3 条：`grep -n "def _build_topbar|def _build_main|...|class CloudView" ...` ↳ `ui/workbench.py:16`（自述注释：在 `_CACHE_FRAMES` 帧缓存上前后走——⏮⏭ 前后帧、时间轴可拖拽、⟲ 回到实时边缘）、`ui/workbench.py:57`：`_CACHE_FRAMES = 2000`。
