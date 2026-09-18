---
id: pyside-package-import-without-qapplication
type: lesson
status: candidate
scope: global
domain: pyside6
tags: [pyside6, qt, import, headless, qapplication, ci]
triggers:
  - "写/审 PySide6 UI 包：要求 headless / CI 下 `python3 -c 'import <pkg>'` 也能通过"
  - "import UI 模块时进程立刻 SIGABRT / exit 134，提示 Must construct a QGuiApplication（失败信号）"
  - "模块顶层直接 QApplication([]) 或构造 QWidget，导致 import 即崩"
  - "要区分『库可导入』与『GUI 探测脚本需要 QApplication』两条不同的要求"
  - "headless 测试失败，怀疑是 import 期副作用（建 app/建窗口）而非断言问题"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a80b-0eb2-7719-ba82-31f673a6db5a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pyside-probe-script-needs-qapplication]
---

主张：PySide6 库代码（非可执行入口）应当能在**不构造 QApplication** 的进程里被 import；验收方式就是裸跑 `python3 -c "import <pkg>"`（不建 app、不 show），进程正常打印 import 成功即达标——模块顶层一旦构造 `QApplication([])` 或 QWidget，headless/CI 下的 import 就会崩。

证据（session 01a0a80b，SPC865 UI 基座车道）：
- 命令：`cd /Users/zodyne/Dev/SPC865 && QT_QPA_PLATFORM=offscreen python3 -m pytest tests/python/test_ui_widgets.py 2>&1 | tail -20 && python3 -c "import spc8…"`（切片对命令文本截断）。
- 结果：`.............  [100%] 13 passed in 0.36s import ok, no QApplic…` —— 即 pytest 13 项全过后，同一行链尾的裸 import 校验进程自报 import 成功且未建 QApplication。
- 同会话的 GUI 探测脚本（命令 6/7/8/11/12/13）则相反：每段都先 `app = QtWidgets.QApplication([...])` 再碰 QWidget/QFont——两种场景的要求不同，不能混。

边界 / 反例：
- 本切片只出现**成功侧**证据；「顶层建 app/控件 → import SIGABRT」的失败现象未在本次命令↔结果里出现，属 PySide6 机制的预期（与 `pyside-probe-script-needs-qapplication` 同源，见 related），引用失败信号时留一分保守。
- 切片把 `python3 -c` 的参数与打印文本都截断了（可见部分 `import spc8…` / `import ok, no QApplic…`），完整断言语句需回原始会话核对。
- 需要真实窗口/事件循环的可执行入口（`__main__`、CLI 脚本）仍应建 QApplication；本条只约束**被 import 的库模块**，不是"任何地方都不许建 app"。
