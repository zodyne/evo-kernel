---
id: restart-discard-stale-accumulation
type: lesson
status: validated
scope: global
domain: data-pipeline
tags: [restart, accumulation, npz, save-discard, replay, buffer]
triggers:
  - "重跑/重启后两轮数据混拼到同一产物（失败信号）"
  - "重启后上一轮半截累积混入本轮"
  - "落盘线程的累积缓冲区要清空"
  - "给管线加 restart/重跑语义，需处理累积状态"
  - "SAVE_DISCARD 丢弃上一轮累积"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a56f-582e-7353-8a3d-42c5ca5a3860
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [analysis-cache-filename-must-key-dataset]
---

# 重跑/重启清累积：投 SAVE_DISCARD 丢弃上一轮半截数据

## 主张

重启/重跑时，落盘线程的**持久累积缓冲区必须显式清空（投 SAVE_DISCARD）**，否则上一轮半截累积会混进本轮产物（npz 混拼）。这是「重跑语义」必须处理的累积状态，不能靠「再写一轮覆盖」糊弄。

## 证据

- 探针 `probe_save.py` 列出 SaveWorker 两处修复：①SAVE_DISCARD 清累积（重跑语义:两轮不混拼）②异常被捕获不静默死。
- 探针结果：`=== A. SAVE_DISCARD 清累积(重跑语义:两轮不混拼) === 结果已落盘: /tmp/probe_save_A.npz`。

## 边界

- 针对「进程内跨轮次复用同一累积缓冲区」；与「落盘缓存文件名未 key 数据集」不同坑（见 related，那条是磁盘缓存文件名问题，这条是内存累积缓冲区清空问题）。
- 适用于任何长时累积再落盘的管线，不止雷达数据路径。
