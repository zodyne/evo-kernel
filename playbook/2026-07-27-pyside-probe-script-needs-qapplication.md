---
id: pyside-probe-script-needs-qapplication
type: lesson
status: validated
scope: global
domain: qt-gui
tags: [pyside6, pyqtgraph, sigabrt, exit-134, qapplication]
triggers:
  - 用 python -c 快速探测 Qt/pyqtgraph 绘图 API
  - pyqtgraph PlotItem/ViewBox 探测脚本报 QPixmap 错误
  - PySide6/Qt 探测脚本 exit code 134 (SIGABRT)
  - GUI 探测崩溃且提示 Must construct a QGuiApplication
  - 离线命令行验证 Qt 绑定 API 是否存在
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:4af1c06f-edee-4b3f-88a3-87e56a8df9b8
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# PySide6/pyqtgraph 探测脚本必须先建 QApplication，否则 SIGABRT(exit 134)

## 主张
任何会实例化 Qt 绘图相关对象（pyqtgraph 的 `PlotItem`/`ViewBox`、`QPixmap`、`QPainter`、字体查询等）的 `python -c "..."` 探测脚本，必须在构造这些对象**之前**先 `app = QApplication([])`，否则进程立即 SIGABRT，exit code 134，报 `QPixmap: Must construct a QGuiApplication before a QPixmap`。

## 为什么
Qt 的像素图/字体/绘制子系统依赖 `QGuiApplication` 已初始化的全局状态。命令行探测若直接 `import pyqtgraph as pg; pg.PlotItem()`，在构造阶段即触发 `QPixmap`/字体查询，此时无 `QGuiApplication`，Qt 调用 `abort()`。这是 `QGuiApplication` 缺失下的**硬崩溃**（非警告、非可忽略异常），整条探测拿不到任何输出。

## 证据（本会话命令对照）
- ❌ `python -c "import pyqtgraph as pg; p=pg.PlotItem(); ..."` → Exit 134 `QPixmap: Must construct a QGuiApplication before a QPixmap`
- ✅ 同脚本前置 `from PySide6.QtWidgets import QApplication` + `app = QApplication([])` → 正常输出 `PlotItem`/`ViewBox` 方法列表

## 边界 / 反例
- 纯非 GUI 的 `QtCore` 类（`QObject`、`Signal`、`QThread` 类型对象本身）探测**不需要** `QApplication`。
- 凡触及任何会触碰 `QPixmap`/字体/绘制的类（拿不准时）就一律先建 `QApplication([])`。
- 探测脚本是「无窗口」场景，建 `QApplication([])` 即可，无需 `show()`，进程结束自然退出。

## 失败信号（未来命中即该想起本条）
- `python -c` 探测 Qt/pyqtgraph 时输出 `QPixmap: Must construct a QGuiApplication before a QPixmap` 后进程以 134 退出。
- 探测脚本没有任何预期输出、直接非零退出码 134。
