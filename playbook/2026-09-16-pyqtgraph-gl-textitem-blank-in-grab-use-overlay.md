---
id: pyqtgraph-gl-textitem-blank-in-grab-use-overlay
type: lesson
status: validated
scope: global
domain: pyside6
tags: [pyqtgraph, opengl, gltextitem, screenshot, overlay, offscreen]
triggers:
  - "pyqtgraph GLTextItem 在 QWidget.grab() / 截图里是空的"
  - "GL 场景文字标签截图为空，屏幕上看得到（失败信号）"
  - "offscreen 平台 QOpenGLWidget 建不出上下文，需要 2D 回退"
  - "想在 3D 视图上叠文字标签且截图稳定"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-16-12-16-39-278-9hqc
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [2026-07-27-qt-offscreen-opengl-context-warnings-nonfatal]
---

# pyqtgraph GLTextItem 在 grab()/截图里是空的：用透明 QWidget 覆盖层画文字

## 主张

pyqtgraph GLTextItem 在 `QWidget.grab()`/截图里是空的（QPainter 画在 paintGL 之外）；GL 场景的文字标签用一层 `WA_TransparentForMouseEvents` 的透明 QWidget 覆盖层，按 `projectionMatrix*viewMatrix` 投影后 QPainter 画，屏幕与截图都稳。

## 边界

offscreen 平台下 QOpenGLWidget 建不出上下文，要留 2D 回退路径给无头自检。
