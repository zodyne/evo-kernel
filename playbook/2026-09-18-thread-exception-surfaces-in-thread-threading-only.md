---
id: 2026-09-18-thread-exception-surfaces-in-thread-threading-only
type: lesson
status: validated
scope: global
domain: python-threads
tags: [threads, traceback, excepthook, stderr]
triggers:
  - "后台线程 traceback 帧栈只见 frames 无抛出异常行（失败信号）"
  - "用主线程 sys.excepthook 观察线程崩溃却什么都收不到"
  - "区分异常传递机制（谁捕获 / 谁打印 / 谁退出）拿不准"
  - "线程崩溃排查想直接看到抛出点而不只是 import 链"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a6a9-cca2-7353-8a3d-42db7cefb5ac
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [background-thread-exception-must-surface]
---

Python 线程抛异常默认**只打印到 stderr、只打 frames、不调用 sys.excepthook、不终止进程**，主线程的 excepthook 不适用于后台线程。切片证据：algommw 两次探针（/tmp/savew_probe.py、/tmp/savew_probe2.py）都复现同一线程栈形态——`Exception in thread chain-save: Traceback (most recent call last):` 后全是帧行（落到 /opt/homebrew/Cellar/python@3.14/3.14.7/.../pathlib/__init__... 底层深处），见不到异常类型/抛出行出现在主线程 excepthook 输出中。

排查动作：threading 模块在 3.8+ 暴露 `threading.excepthook`（可重定向到日志/UI），sys.excepthook 只管主线程；排查时先确认看的是哪个 hook。
边界/反例：守护线程死亡不结束进程；若异常发生在解释器关闭阶段可能连 traceback 都不完整。
