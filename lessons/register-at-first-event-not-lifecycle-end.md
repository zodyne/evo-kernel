---
id: register-at-first-event-not-lifecycle-end
type: lesson
status: candidate
scope: global
domain: telemetry
tags: [hooks, registration, upsert, session-refs, lifecycle]
triggers:
  - "把登记/计数/埋点挂在 SessionEnd、进程退出、关闭事件这类生命周期末尾钩子上"
  - "登记表和原始日志对不上：大量事件有日志却没有登记行（失败信号）"
  - "设计会话/任务/作业系统的登记点，选「何时落账」"
  - "结束钩子依赖对端优雅退出，而被登记方可能被 kill、崩溃或绕过 hook"
  - "登记前移到事件起点后怕重复登记，需要幂等 upsert"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:b6cf7fd7-73c7-4cef-b538-5428b694a71b
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [self-registration-hook-self-pollution-loop, coverage-denominator-is-a-moving-target, claude-hook-sessionstart-no-prompt]
---

# 登记挂生命周期结束钩子实测漏掉一半：落账要前移到事件首次发生点 + 幂等 upsert

## 主张

任何「登记/落账」动作如果只在**生命周期结束事件**（SessionEnd、process exit、关闭回调）触发，
实际覆盖率会远低于直觉——结束事件依赖对端优雅走完整个生命周期，而被登记方可能崩溃、被 kill、
或走了一条不触发该 hook 的路径。登记必须**前移到事件首次可观测的发生点**，并用幂等 upsert
吸收重复触发；宁可多写一次，不可只等最后一次。

## 为什么

2026-07-29 实测 Evo-Kernel 的 session-refs 台账（登记点原本在 SessionEnd hook）：
515 个有 session 归属的注入实例里，**43 个 session / 266 实例（51.7%）从未登记**。
这 43 个里只有 7 个（6%）的 transcript 还留在磁盘上——存量永远追不回，
漏登记直接变成对账覆盖率的永久缺口（见 related 的分母条目）。

修复（commit `b4cf1c5`）：登记前移到**首次 hook-recall**（事件第一次发生即可观测处），
对同一 session 的重复触发做 upsert。smoke 新增 I 组用例固化该行为
（「首次 hook-recall 即登记，不等 SessionEnd」），PASS=99 FAIL=0。

## 反例 / 边界

- 前移登记引入新风险：后台驱动器/定时任务调用同一入口会造成自登记污染
  （见 related 的自污染条目）。upsert 之外还要按调用来源过滤。
- 只读探针类事件若不需要登记，前移反而放大噪声——本条适用于「漏掉就追不回」的台账。
- 结束钩子不是没用：它适合记「完整结束」语义（结束时间戳、退出码），但不适合当唯一登记点。

## 证据

- 归因统计：join `ops/log/recall.jsonl` 与 `inbox/session-refs.jsonl`，
  输出「未登记 43 session / 266 实例 / 51.7%」。
- commit `b4cf1c5` `fix(session-refs): 登记前移到首次 hook-recall + upsert，堵住 51.7% 的登记漏失`。
- `test/smoke.sh` I 组：refs 写入/哨兵/schema、inbox 渲染计数、登记前移，全绿。
