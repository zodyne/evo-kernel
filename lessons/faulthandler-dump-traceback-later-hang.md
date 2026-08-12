---
id: faulthandler-dump-traceback-later-hang
type: lesson
status: candidate
scope: global
domain: debugging
tags: [python, faulthandler, hang, macos]
triggers:
  - "Python 程序（GUI/数据加载）疑似挂死，想拿堆栈定位卡在哪一行"
  - "macOS 上想给命令加超时却发现没有 timeout 命令"
  - "进程 CPU 不动、无输出，分不清是死循环还是阻塞 I/O"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:a522a07c-f185-4449-9fd7-d0f755c0b02f
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [macos-no-timeout-command]
---

Python 程序疑似挂死时，用 `faulthandler.dump_traceback_later(N, exit=True)` 在 N 秒后自动 dump 全线程堆栈并退出，直接定位卡住的那一行——不需要外部 timeout 命令。

为什么：macOS 无 GNU `timeout`（`command not found: timeout`），无法外包超时；而在脚本内加 `faulthandler.dump_traceback_later(60, exit=True)`，挂死时输出 "Timeout (0:01:00)! Thread ... (most recent call first): File ..." 形式的堆栈，指到具体文件行号。比盲目加 print 或接 debugger 快得多，且对 GUI 事件循环挂死同样有效。

边界：`exit=True` 会杀进程，只用于诊断；生产看门狗另设。

证据：会话内先 `timeout 90 python3 ...` 报 command not found，改用 `python3 -c "import faulthandler..."` 后拿到 "Timeout (0:01:00)! ... most recent call first" 堆栈输出。
