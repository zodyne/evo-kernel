---
id: board-reload-stop-old-thread-first
type: lesson
status: validated
scope: global
domain: concurrency
tags: [thread, race, hot-reload, gui, lifecycle, join]
triggers:
  - "换板/重载/切换会话时旧会话数据被清空（失败信号）"
  - "热切换 UI 会话或数据源，旧航迹/状态丢失"
  - "新处理线程先起、旧线程后停的顺序竞态"
  - "给 GUI/管线加会话切换，需确定线程 stop/join 次序"
  - "线程生命周期：停旧 → join → 关旧窗 → 起新"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a56f-582e-7353-8a3d-42c5ca5a3860
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [background-thread-exception-must-surface]
---

# 换板/重载线程竞态：先停旧线程并 join，再起新线程

## 主张

换板/重载会话时，必须**先停旧处理线程并 join、关旧窗口，再起新线程**。原次序是「先亮新窗、后停旧线程」，新旧两个 ChainSession 的落盘哨兵互相踩踏，导致旧会话航迹被清零（修复前实测复现）。起新线程必须排在「停旧 + join + 关旧窗」之后。

## 证据

- 行序映射（修复前）：`L 185 window.show()  L 193 old_pipeline.stop()  L 194 old_pipeline.join()  L 199 old_saver.queue.put(None)` —— 新窗先亮、旧线程后停。
- 行序映射（修复后，静态断言 PASS）：`L 185 新窗亮 → L 193 停旧处理线程 → L 194 等旧线程退出 → L 199 旧落盘退出哨兵 → L 200 等旧落盘退出 → L 202 关旧窗 → L 206 起新处理线程 → L 208 起新落盘`。

## 边界

- 针对「热切换数据源/会话」这类有线程生命周期重叠的场景；单线程或进程整体重启不适用。
- 关键不是「停旧」而是**次序**：新线程必须在旧线程及其落盘哨兵完全退出后才起。
