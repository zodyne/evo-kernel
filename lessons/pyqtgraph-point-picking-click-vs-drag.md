---
id: pyqtgraph-point-picking-click-vs-drag
type: lesson
status: deprecated
scope: global
domain: visualization
tags:
- pyqtgraph
- opengl
- picking
- qt
- mouse-event
triggers:
- pyqtgraph/GL 3D 视图里加鼠标点选点云的功能
- 旋转视角时误触发选点（失败信号：点击与拖拽没区分）
- 屏幕重叠点选到了背后那个而不是看见的那个
- macOS 上 Cmd/Ctrl 加选修饰键不生效
created: 2026-07-28
evidence:
  helpful: 0
  harmful: 0
verified_by: none
source: session:b417294c
last_verified: 2026-07-28
superseded_by: skill:pyside6-desktop-apps
schema_version: 1
related:
- 2026-07-28-macos-qt-cmd-key-maps-to-control-modifier
- 2026-07-28-qmatrix4x4-data-returns-column-major-tuple
---

# pyqtgraph 3D 点选：点击/拖拽按位移阈值分开，拾取先屏幕距离再 NDC 深度

**主张**：GL 视图里实现点选的三条实测做法：① **点击 vs 拖拽**：按下/抬起的位移 ≤4px 才算点击，否则每转一次视角都误选；② **拾取**：`project()` 取 MVP 矩阵做 numpy 批量投影（`copyDataTo()` 行主序），得屏幕坐标+NDC 深度，先按离光标距离筛（半径 ~10px），**再在这批里取离相机最近的**——屏幕重叠时选到的是看见的那个；③ **多选修饰键**：macOS 上 Qt 把 ⌘ 映射成 Control、物理 Ctrl 映射成 Meta，两个修饰键都要收下。

**边界**：加选状态下点空白不应清空选择（一次误点全丢）；清空只走普通单击空白/Esc/显式按钮。标记渲染用单个 `GLLinePlotItem` 逐顶点上色，不按点数堆 GL item（性能）。

**证据**：session b417294c，viewer_filtered.py `PickView`（+287 行），40 帧 9367 点实测 ctrl+click 累积、列表坐标与 3D 准星逐点吻合。
