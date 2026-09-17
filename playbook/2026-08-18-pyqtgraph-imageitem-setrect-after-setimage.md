---
id: pyqtgraph-imageitem-setrect-after-setimage
type: lesson
status: validated
scope: global
domain: pyqtgraph
tags: [pyqtgraph, imageitem, setrect, setimage, viewbox]
triggers:
  - "pyqtgraph ImageItem.setRect 在 setImage 之前调用，坐标轴量级错几百倍"
  - "pyqtgraph 图像显示比例 / 坐标轴比例不对（失败信号）"
  - "ImageItem 的 rect 该在什么时机设置"
  - "pyqtgraph ImageItem 显示得到垃圾比例"
created: 2026-08-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-08-18-21-59-04-704-cctn
last_verified: 2026-08-18
superseded_by: null
schema_version: 1
related: []
---

# 主张

pyqtgraph `ImageItem.setRect` 的变换**由调用时刻的图像像素尺寸推导**；在 `setImage` 之前调用 `setRect` 会得到垃圾比例（坐标轴量级错几百倍）。

# 修法

把 rect 存下来，**每次 `setImage` 之后再 `setRect`**。

# 证据

capture `capture-2026-08-18-21-59-04-704-cctn` 原文（未改写）：「pyqtgraph ImageItem.setRect 的变换由调用时刻的图像像素尺寸推导；在 setImage 之前调用 setRect 会得到垃圾比例（坐标轴量级错几百倍）。正确做法：把 rect 存下来，每次 setImage 之后再 setRect。」capture 内无命令输出，证据等级 human。
