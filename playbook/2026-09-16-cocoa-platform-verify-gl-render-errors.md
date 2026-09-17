---
id: cocoa-platform-verify-gl-render-errors
type: lesson
status: validated
scope: global
domain: pyside6
tags: [pyqtgraph, opengl, offscreen, ui-verification]
triggers:
  - "PySide6/pyqtgraph 窗口离屏 pytest 全绿，但怀疑真实 OpenGL 渲染有错"
  - "测试绿但 GUI 实际渲染黑屏/错乱，要证明渲染真的正确而非只看断言"
  - "想验证 pyqtgraph GLViewWidget / 3D 视图在真实显示平台上无绘制错误"
  - "offscreen 平台跑通但 cocoa 平台下 OpenGL 报错/画面异常"
  - "交付 GUI 前做真实渲染冒烟，而不是只跑逻辑单测"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a851-cb59-7719-ba82-320642646fd4
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [pyqtgraph-surface-vertex-math-decouple-from-gl, 2026-07-27-qt-offscreen-opengl-context-warnings-nonfatal, pyside-probe-script-needs-qapplication]
---

offscreen 平台的 pytest 全绿（16 passed）不能证明真实 OpenGL 渲染无错；要验证真实渲染，用 `QT_QPA_PLATFORM=cocoa` 跑窗口冒烟脚本，把 stderr 重定向到日志文件，再 grep "Error while drawing" 计数确认 GL 无绘制错误。

SPC865 工作台改造里，offscreen pytest 一直 16 passed，但为确认真实渲染无 GL 错误，用 `QT_QPA_PLATFORM=cocoa python3 - <<'PY' 2>/tmp/gl_smoke_v2.log` 跑窗口冒烟，结果打印 `window 1560 950 False exit=0 --- Error while drawing 条数: 0`，据此确认 cocoa 平台下 OpenGL 绘制无错误；再用 `2>/tmp/gl_smoke_v2_mesh.log` 对 mesh 视图做同样验证。

反例/边界：offscreen 平台构造 GL 上下文可能直接失败（见 2026-07-27-qt-offscreen-opengl-context-warnings-nonfatal），那只能证明逻辑跑通，不能覆盖真实平台下的 GL 绘制路径；cocoa 冒烟要连窗口一起真实构造，才能触发真实 GL 错误计数。日志里 "Error while drawing" 计数须显式打印（脚本里 grep/计数），不能只靠 exit code 判断——GL 绘制错误通常不改变进程退出码。
