---
id: pyqtgraph-surface-vertex-math-decouple-from-gl
type: lesson
status: validated
scope: global
domain: pyqtgraph
tags: [pyqtgraph, opengl, GLSurfacePlotItem, 3d, 网面, mesh, pyside6]
triggers:
  - "pyqtgraph.opengl 画 3D 网面/曲面，有 OpenGL 的平台上报 IndexError 或 SIGSEGV"
  - "给 GLSurfacePlotItem 传颜色数组报 AttributeError 或崩溃"
  - "想对 3D 顶点计算做单元测试但 GL 上下文在无头环境建不起来"
  - "3D 视图测试绿但真实渲染崩，需要隔离「算顶点」与「GL 渲染」"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7da-1c77-7719-ba82-31e9d9d40735
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [cocoa-platform-verify-gl-render-errors, 2026-07-27-qt-offscreen-opengl-context-warnings-nonfatal]
---

pyqtgraph 的 `GLSurfacePlotItem` 没有 `meshData` 属性（`meshData` 在 `GLMeshItem` 上），传颜色数组形状不符会 IndexError→SIGSEGV。把「算顶点/算颜色」拆成纯 numpy 数据类（与 `pyqtgraph.opengl` 无关）再喂给 GL 层：顶点计算才可被无头 pytest 覆盖，GL 崩溃被隔离成独立层单独在 cocoa 平台验证。

实测：views.py 三维网面在有 OpenGL 平台崩溃（IndexError→SIGSEGV），拆出 `MeshSurface` 纯 numpy 类后各波束绘制错误=0、TypeError=0。
