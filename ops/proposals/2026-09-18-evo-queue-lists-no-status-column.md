---
id: evo-queue-lists-no-status-column
type: lesson
status: candidate
scope: project:evo-kernel
domain: evo-kernel
tags: [evo-distill, queue, 对账]
triggers:
  - "跑 evo queue 想看哪些会话蒸馏完成/失败"
  - "拿 evo queue 行数推断蒸馏进度"
  - "想在 queue 输出里找状态或结果列（失败信号）"
  - "queue 行数很多就怀疑积压没消化"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af9e-b3c1-764c-a77e-5180607e51ae
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [distill-log-done-line-is-the-completion-ledger]
---
**主张**：`bin/evo queue` 的输出只有「session_id + transcript 路径」两列，不含完成/失败状态；它只是待处理清单，不能用来回答「某会话是否蒸馏完成」，也不能拿行数当积压程度指标。

**为什么**：2026-09-17 排查「evo 会话是否完成了蒸馏」时，`./bin/evo queue`（135 行）实际输出全部是 `sid<TAB>路径`，没有状态列；把 queue 当完成台账会得出「全都还没蒸馏」的错误结论。

**边界/反例**：
- 需要完成态时去 `ops/log/distill.log` 找 `done <sid> — DISTILL_OK <n>` 行；
- queue 适合回答「还有哪些待处理」，不适合回答「处理得怎么样」。

**证据**：同会话切片：`./bin/evo queue 2>&1 | head -30` 与 `./bin/evo queue 2>/dev/null | wc -l`（=135）输出均为 sid+路径两列，无状态字段。
