---
id: pyqtgraph-imageitem-maptodata-transposed-coords
type: lesson
status: candidate
scope: global
domain: pyqtgraph
tags: [pyqtgraph, imageitem, maptodata, axisorder, coordinates]
triggers:
  - "写/审 ImageItem 坐标映射探针：把视图坐标 mapToData 回数据坐标"
  - "同一份 mapToData 探针在不同脚本/会话里读出的两个分量对调（失败信号）"
  - "核验 Range–Doppler 图上读数的行列方向，想确认 mapToData 的分量顺序由谁决定"
  - "离屏探针里 ImageItem 未接入 ViewBox（viewRect 为 None），问这时坐标读数还算不算数"
  - "给 pyqtgraph 图像写点击/读数坐标换算，想核对 row-major 与 col-major 的差异"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-5368-73b1-bdd8-c2d88804e74e
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pyqtgraph-imageitem-axisorder-from-global-config, pyqtgraph-imageitem-axisorder-is-attribute, image-rect-left-edge-from-data-axis-first-element]
---

**主张**：`ImageItem.mapToData(QPointF)` 返回的两个分量顺序随轴序翻转——同一输入点 `QPointF(10.5, 100.5)`，默认（col-major）探针返回 `QPointF(10.5, 100.5)`，row-major 探针返回 `QPointF(100.5, 10.5)`。所以任何把视图/场景坐标读回数据坐标的探针或核验脚本，都要在打印结果的同时打印 `image.axisOrder`；否则两次运行的数字看起来都「正常」，只有并排比对才会发现 x/y 被对调。

**为什么**：轴序决定 `mapToData` 把输入点解释成 (col, row) 还是 (row, col)（`axisOrder` 本身是实例化时从全局 `imageAxisOrder` 取的快照，见 related）。探针不记录轴序时，读数对调这件事在单次输出里不可见，会污染「图上目标位置对不对」这类核验结论。

**证据**（session 01a0b2ce 切片，命令 ↔ 结果）：
- 同系列探针 `mapdata2.py` 先确认接口形态：打印 `mapToData sig: (self, obj)`（另有 `viewRect: PySide6.QtCore.QRectF(0.000000, 0.000000, 1.000000, 1.000000)`）。
- 默认轴序探针 `mapdata3.py`（该次输出未回显 axisOrder）：`viewRect: None mapToData(QPointF(10.5,100.5))= PySide6.QtCore.QPointF(10.500000, 100.500000)`。
- row-major 探针 `mapdata4.py`（探针自己回显了轴序）：`row-major axisOrder: row-major viewRect: None mapToData= PySide6.QtCore.QPointF(100.500000, 10.500000)`——两次返回值相比，两个分量对调。

**反例 / 边界**：
- 切片只保留命令首行（heredoc 正文未保留）与结果行；row-major 那条没有回显输入点，「与默认轴序探针同输入」是按 mapdata3/mapdata4 属同一探针系列、只改了轴序这一处推定。
- 两次探针的 `viewRect` 都是 `None`（ImageItem 未接入 ViewBox），即读数来自独立 item 的映射；接进真实 ViewBox 后的数值切片里没有。
- 两个探针都设了 `QT_QPA_PLATFORM=offscreen`，即该行为在离屏模式下成立。
- 本条与 related 两条的分工：那两条讲 `axisOrder` 的值从哪来、按属性取值；本条讲这个值如何反映在 `mapToData` 的返回分量顺序上。
