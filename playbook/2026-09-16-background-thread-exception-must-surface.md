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
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [board-reload-stop-old-thread-first]
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
