---
id: pyside6-interpreter-exit-segv-os-exit
type: lesson
status: validated
scope: global
domain: pyside6
tags: [pyside6, pyqtgraph, python3.14, sigsegv, shutdown, os-exit, macos]
triggers:
  - "写/跑 PySide6·pyqtgraph 一次性探针或 GUI 入口脚本，脚本跑完后 macOS 弹「Python quit unexpectedly」（失败信号）"
  - "Python-*.ips 崩溃栈顶是 atexit → destroyQCoreApplication → QGraphicsScene/QGraphicsWidget dtor → func_dealloc（失败信号）"
  - "GUI 脚本退出码 139 / SIGSEGV，但全程没有任何 Python traceback"
  - "想让 GUI 脚本收尾时不进 atexit / Py_Finalize（窗口关了但控件树还活着就退出）"
  - "用了 os._exit 收尾，日志/print 少了几行（失败信号：漏了 flush）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a90b-fa1b-769f-b2a4-6c411d10843a
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [pyside-probe-script-needs-qapplication, python-context-manager-mc-crash-proofs-output]
---

# PySide6 GUI 探针在解释器收官时 SIGSEGV：收尾改走 flush + `os._exit`

## 主张

macOS + Homebrew framework 形态 CPython 3.14 + PySide6 6.11 下，形状为「建 `QApplication` → `show()` →
`grab()` / 跑事件循环 → 脚本结束、**控件树仍然活着**」的 PySide6/pyqtgraph 探针，会在**解释器收官**时
收到 SIGSEGV（macOS 弹「Python quit unexpectedly」）。收尾一律改成：

```python
sys.stdout.flush(); sys.stderr.flush()   # 必须，见边界
os._exit(0)                              # 跳过 atexit / Py_Finalize
```

崩栈固定为：`atexit_callfuncs → SbkQtCoreModule___moduleShutdown → PySide::destroyQCoreApplication →
QGraphicsScene dtor → QGraphicsWidget dtor → …::boundingRect() → Sbk_GetPyOverride → _Py_Dealloc → func_dealloc`。
即 Qt 侧析构活控件树时回调进**已经释放/半拆的 Python 包装对象**。所以这不是脚本逻辑写错；
「窗口正常关闭」也不豁免——这一类的崩溃全都是正常退出（而非被信号打断）触发的。

## 为什么

`raise SystemExit(main())` 或脚本自然结束都会进 `atexit` + `Py_Finalize`；PySide6 在这条路径上销毁
`QCoreApplication` 并连带析构仍存活的控件树。`os._exit` 直接终结进程，不跑 atexit、不拆解释器，
这一整类「退出时踩空」因此消失。Homebrew 的 python@3.14 是 bundle 形态
（`Frameworks/Python.framework/Versions/3.14/Resources/Python.app`、进程名 `Python`），
系统才会为它弹窗——普通非 bundle 解释器不弹。

## 证据（2026-09-16 会话内命令与结果）

- `~/Library/Logs/DiagnosticReports/Python-*.ips` 一天 19 份，其中 **9 份栈完全相同**、全在 `libqoffscreen`
  （无头）下、全在退出路径上（按 `(app_version, exception.signal, 前 6 帧)` 归并得出该分类）。
- 对照实验 `/tmp/guard_e2e.py`（offscreen + `QTimer` 自动关窗）：
  默认 → `exit=0`、`main()` 之后那句哨兵 `print` **不出现**（说明 `os._exit` 生效）、崩溃报告数 21→21；
  设逃生口 `SPC865_UI_EXIT_GUARD=0` → 哨兵 print **出现**（退回正常收官路径）。
- 回归：`QT_QPA_PLATFORM=offscreen pytest tests/python -q` exit 0、`spc865_ui.py --check` exit 0。
- flush 的必要性实测：`python3 -c "print('x'); os._exit(0)" | cat` → 管道下那行**整行丢失**；
  先 `sys.stdout.flush()` 再 `os._exit` 才出现。

## 反例 / 边界

- **本会话没有复现崩溃本身**：当前代码状态下 `/tmp/win_shot.py` 连跑 6 次、全量 pytest 均 exit 0
  （仓库代码当天改过），所以「`os._exit` 消除崩溃」是从 9 份同栈报告 + 退出路径**推得**的；
  被直接证实的只是「守护确实生效」（哨兵 print 的对照实验）。别把它当成已复现的最小复现。
- 只覆盖「退出时崩」这一类。同一天另有 `GLEngine/glDrawArrays` 7 次（cocoa，mesh/OpenGL 渲染路）、
  `libalgommw_bind/prvGridPeak2D` 2 次（真 C bug）、`QFrame` 构造 SIGABRT 1 次
  （`QApplication` 之前建控件）——`os._exit` 治不了这些。
- `os._exit` 跳过全部收尾：若代码依赖 `atexit`（本会话已 grep 确认目标仓库无此依赖）、要落盘或删临时文件，
  必须自己在 `os._exit` 之前做完。
- 给可被 import 的入口加这条时要留逃生口（如 env 开关），否则测试里 in-process 调 `main()` 会被
  `os._exit` 直接带走，后续断言全部消失。
