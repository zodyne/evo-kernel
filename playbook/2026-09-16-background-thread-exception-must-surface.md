---
id: background-thread-exception-must-surface
type: lesson
status: validated
scope: global
domain: error-handling
tags: [background-thread, exception, silent-failure, pipeline, gui]
triggers:
  - "后台线程静默退出/挂死，主程序无感知（失败信号）"
  - "落盘/处理线程异常被 except 吞掉"
  - "给后台线程加错误上浮（shutdown/--check/UI）"
  - "管线线程写文件失败但无报错"
  - "线程异常定位困难"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a56f-582e-7353-8a3d-42c5ca5a3860
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [board-reload-stop-old-thread-first, thread-exception-surfaces-in-thread-threading-only]
---

# 后台线程异常不能静默吞：存 error 字段并上浮

## 主张

后台处理/落盘线程的 `except` 块**不能只吞掉异常静默退出**。要捕获后存到 `pipeline.error` 字段，并在 shutdown/`--check`/UI 横幅上浮，否则线程静默死掉后主程序无任何信号，难以定位。探针在只读目录触发落盘后，修复为「记录 PermissionError + 线程退出」+ 三处上浮。

## 证据

- 探针 `probe_save.py` 在只读目录触发：`落盘线程异常:PermissionError(13, 'Permission denied')`，验证异常被捕获且不静默死。
- `view_tracks_3d.py:101: if pipeline.error is not None` —— 错误从后台线程上浮到 UI 层读取。

## 边界

- 针对「后台线程 + 主线程异步」这类静默故障；主线程同步异常天然会冒出来。
- 上浮至少给一条可读路径（error 字段 + 一处对外暴露），不要只打日志。
- **静默有两种形态，都要覆盖**：① 有 `except` 但只吞掉（本条目主体）；② **根本没有 try/except**（2026-09-18 补，algommw `pipeline.py:_run`，:405-419）——下游 `_flush`（:421）里的 `mkdir`（:439）/ `np.savez_compressed`（:440）抛异常直接把线程带走，**线程死了、主进程照常跑、UI 无任何提示**，业务只剩静默的数据断流。只按①去审查会漏掉②：代码里搜不到 `except` 不等于线程不会静默死。
- 机制侧见 related `thread-exception-surfaces-in-thread-threading-only`：线程异常默认只打到 stderr、**不调用 `sys.excepthook`**（主线程那个 hook 收不到），要重定向得用 `threading.excepthook`；守护线程死亡不结束进程。所以「上浮」是一段必须自己写的代码，不是解释器的默认行为。
