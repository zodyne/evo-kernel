---
id: harness-slowness-attribute-via-child-cpu-time
type: lesson
status: candidate
scope: global
domain: pi-harness
tags: [pi, performance, diagnosis, ps, child-process, cpu-time]
triggers:
  - "某个 pi 会话/任务跑了很久没结果，第一反应是 pi 或模型变慢"
  - "要判断一个长时间运行的工具调用是在推进、在等外部，还是已经死锁"
  - "ps 看到 pi 进程 %CPU 很低但墙钟时间极长（失败信号：耗时不在 harness 自身）"
  - "排除『网关/模型慢』之前，还没查过 pi 有没有活着的子进程"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09e85-e0fb-75a9-9255-6adde3fc97aa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [2026-09-16-bash-guard-blocks-pathless-recursive-scan, pi-print-mode-waits-on-non-tty-stdin]
---

**主张**：pi 会话"跑得慢"时先量主进程与其子进程的 CPU 时间，再谈网关/模型。诊断顺序：`ps -o pid,etime,time,%cpu,command` 看墙钟与 CPU 时间的比例 → `pgrep -P <pid>` 列子进程 → `lsof -p <child>` 看它卡在哪个文件。实测那个 2h17m 无结果的 pi 主进程只耗 `0:45.77` CPU（0.6%）——时间全在等它派生的 `grep` 子进程（两次采样 CPU 已 26:34，正在逐字节读 `~/Dev/radar-data` 下的 .bin 数据）。

**为什么**：墙钟长、CPU 时间短 ⇒ 主进程在"等"（I/O、子进程、网络），不是自己在算。归因错了就会去改网关/模型/prompt，而真正该处理的是那个失控的子进程。

**证据**（本会话命令 ↔ 结果）：
- `ps -o pid,etime,time,%cpu,command -p 86932` → `86932 02:17:34 0:45.77 0.6 pi`；同一时刻另外两个 pi 是 `06:05 / 1.4%`、`01:13 / 5.5%`——只有它在"墙钟极长、CPU 极低"这一档。
- 两次采样子进程：`T0 cpu=26:34.35  file: /Users/zodyne/Dev/radar-data/suc221/raw_adc/20260812/SUC221_...bin`（`ps -o time=` + `lsof`），确认它一直在扫雷达数据、不是在死锁。
- 交叉验证代价：单文件 200MB 的 grep 扫描 `real 10.96s`（user 10.29），同查询 `rg` 只需 0.785–2.2s——慢的是子进程的扫描方式。

**边界/反例**：CPU 时间短也可能是卡在不会返回的网络等待，判据是"先区分在算还是在等"，不是"CPU 低就一定没事"；子进程 CPU 时间在两次采样间持续增长，才能说它在推进而非死锁（本会话正是用两次采样做了这个区分）。
