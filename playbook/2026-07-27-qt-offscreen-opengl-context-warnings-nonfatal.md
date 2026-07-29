---
id: 2026-07-27-qt-offscreen-opengl-context-warnings-nonfatal
type: playbook
status: validated
scope: global
domain: qt-rendering
tags: [qt, pyqt, pyside, pyqtgraph, opengl, offscreen, headless, ci, screenshot]
triggers:
  - 在无显示器机器/CI 上跑 PyQt/PySide/pyqtgraph 应用，想离屏截图或构造 GL 窗口
  - QT_QPA_PLATFORM=offscreen 跑 Qt 程序报 "This plugin does not support createPlatformOpenGLContext" / "QOpenGLWidget: Failed to create context" 就判定离屏渲染不可用
  - pyqtgraph.opengl 在 headless 环境构造 GLViewWidget 报上下文失败，想放弃离屏改找真实显示
  - 需要在服务器/CI 上对 Qt OpenGL 窗口做 grabFramebuffer 截图回归
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:9c7257e9-4890-48f8-b144-4f90a46031e3
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---

# QT_QPA_PLATFORM=offscreen 下 Qt/OpenGL 的"Failed to create context"告警通常非致命

在无显示器的机器上设 `QT_QPA_PLATFORM=offscreen` 即可构造 Qt 窗口并离屏渲染；当机器没有真实 GPU/OpenGL 上下文时，会打印 `This plugin does not support createPlatformOpenGLContext!` / `QOpenGLWidget: Failed to create context` 等吓人告警——但这些告警**往往非致命**：离屏 framebuffer 抓取（`grabFramebuffer` / `QImage` 截屏）仍能产出有效图像。**别看到这些告警就放弃离屏渲染**，先验证输出是否真的产出了。

## 为什么

"Failed to create context" 读起来像硬失败，直觉是"这台机器跑不了 OpenGL，得换有显示/GPU 的环境"。但 offscreen 平台插件走的是软件/离屏路径，构造真实 on-screen GL 上下文那一步本来就会失败并告警——只要你不进实际的事件循环绘制到屏幕，而是用 `grabFramebuffer` 把内容抓成图像，渲染照样完成。本会话在 macOS 上 `QT_QPA_PLATFORM=offscreen` 跑 pyqtgraph OpenGL 点云查看器：stderr 满屏 `createPlatformOpenGLContext`/`Failed to create context`，但 `grabFrameBuffer` 截图全部成功落盘（`gl_斜视.png`/`gl_俯视.png`/`gl_侧视.png`/`win_full.png` …），smoke 测试也"全部通过"。

## 怎么做

1. 设 `QT_QPA_PLATFORM=offscreen`（或代码里 `QApplication.setAttribute(Qt.AA_UseSoftwareOpenGL)` 之类）跑起来，**忽略** create-context 类告警。
2. 实际触发一次 `grabFramebuffer`（或 `widget.grab()`）并落盘，检查图片尺寸/内容非空——能产出即说明离屏渲染可用。
3. 只在图片为空/全黑/尺寸为 0 时才认为离屏真不可用，再去考虑 `mesa`/软件 GL / 真实显示。

## 边界

- 告警"通常非致命"≠"绝不致命"：若代码依赖实时 on-screen GL 管线（如着色器反馈、`glReadPixels` 读回屏幕像素），离屏可能拿不到正确结果——以实际输出为准。
- 不同 Qt 版本/平台插件行为有差；本证据来自 macOS + Qt offscreen 插件 + pyqtgraph 0.14.0。
- 诊断方向是"先验证产出再下判断"，不保证所有 GL 特性在离屏下都等价。
