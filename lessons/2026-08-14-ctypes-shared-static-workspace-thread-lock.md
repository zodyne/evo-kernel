---
id: ctypes-shared-static-workspace-thread-lock
type: lesson
status: candidate
scope: global
domain: concurrency
tags: [ctypes, ffi, gil, thread-safety, lock, radar]
triggers:
  - "ctypes 桥接的 C/C++ 库里有 static/global 工作区，多线程调用结果错乱"
  - "GUI 线程与后台线程同时调同一个 CDLL 函数，结果与串行基线不符"
  - "并发调用 C 库偶尔返回假错误码（失败信号）"
  - "判断某个 ctypes 桥接是否需要模块级 threading.Lock"
  - "ctypes 调用期间释放 GIL 导致真并发踩同一块静态缓冲区"
created: 2026-08-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-14-04-40-07-968-bzpd
last_verified: 2026-08-14
superseded_by: null
schema_version: 1
related: []
---

# 主张

ctypes 桥接 C/C++ 库时，库内的 `static`/global 工作区是**进程级共享**的：多个 `CDLL` 实例 `dlopen` 同一路径返回同一映像，ctypes 调用期间又释放 GIL，于是 GUI 线程与后台线程会真并发地踩同一块静态缓冲区。

修法：模块级 `threading.Lock` 包住所有 C 调用。

# 判据

看 `.cpp` 里有没有 `namespace{}` 静态工作区——有就要加锁。

# 证据

实测 SUC221 `cfar_bridge`：并发 60×2 轮有 108 次结果与串行基线不符 + 8 次假错误码，串行 0/120。
