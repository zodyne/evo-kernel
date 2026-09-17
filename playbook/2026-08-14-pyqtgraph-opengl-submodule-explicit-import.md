---
id: pyqtgraph-opengl-submodule-explicit-import
type: lesson
status: validated
scope: global
domain: pyqtgraph
tags: [pyqtgraph, opengl, import, silent-failure, smoke-test]
triggers:
  - "pg.opengl.GLViewWidget() 报 AttributeError"
  - "pyqtgraph 3D 功能静默死掉，冒烟测试只打印 gl_ok 不断言（失败信号）"
  - "try/except Exception 吞掉 AttributeError 伪装成 'OpenGL 初始化失败'"
  - "写 pyqtgraph 冒烟测试需要断言 3D 视图真的可用"
  - "需要显式 import pyqtgraph.opengl"
created: 2026-08-14
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-08-14-04-09-23-859-qjw7
last_verified: 2026-08-14
superseded_by: null
schema_version: 1
related: [2026-07-27-qt-offscreen-opengl-context-warnings-nonfatal, pyqtgraph-surface-vertex-math-decouple-from-gl]
---

# 主张

pyqtgraph 不会自动导入 `opengl` 子模块：直接用 `pg.opengl.GLViewWidget()` 会抛 `AttributeError`。必须显式 `import pyqtgraph.opengl`。

# 为什么危险

若这个 `AttributeError` 被 `try/except Exception` 吞掉，就会伪装成「OpenGL 初始化失败」，3D 功能静默死掉——真实原因只是少一行 import。

# 边界（测试侧）

冒烟测试只打印 `gl_ok` 而不断言 → 一路绿灯。必须让冒烟测试对 3D 可用性下断言，否则这类静默失败无法被测试发现。

# 证据

capture `capture-2026-08-14-04-09-23-859-qjw7` 原文（未改写）：「pyqtgraph 不会自动导入 opengl 子模块:直接用 pg.opengl.GLViewWidget() 会抛 AttributeError,若被 try/except Exception 吞掉会伪装成'OpenGL 初始化失败',3D 功能静默死掉。必须显式 import pyqtgraph.opengl。冒烟测试只打印 gl_ok 不断言 → 一路绿灯。」capture 内无命令输出，证据等级 human。
