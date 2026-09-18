---
id: drain-self-stop-liveness-verdict
type: lesson
status: candidate
scope: project:evo-kernel
domain: evo-kernel
tags: [evo-drain, liveness, ps, 巡检, 停止条件]
triggers:
  - "ps 里找不到 evo-drain.sh 进程，要判飞轮是崩了还是正常收工"
  - "巡检 evo drain，队列仍有积压但进程消失（失败信号：想直接写「飞轮挂了」）"
  - "手上只有 ps 无匹配就准备下「drain 已死/被 kill」的结论"
  - "写 drain 状态报告，要给出「还在跑 / 已停止」的判定依据"
  - "drain.log 末行不是 done/fail 而是一条终止记录，不确定算不算异常"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2f3-86b5-73b1-bdd8-c2dceaa1549e
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [log-gap-is-not-process-hang-check-load, ps-script-name-match-hits-unrelated-copy, distill-log-done-line-is-the-completion-ledger]
---

**主张**：`evo-drain.sh` 是有限轮次驱动器，会按自己的停止条件收工退出——「`ps` 无匹配」是它的**预期终态**而不是死亡信号；下「已停止」结论要 `ps` 无匹配 **且** `ops/log/drain.log` 末行是它自己的终止记录，两条信号一致才算数。

**为什么**：drain 的停止条件是显式的三选一（`evo-drain.sh` 头部：`--until N` 队列 ≤ N、`--budget-hours H` 墙钟预算、`--max-empty N` 连续 N 轮零进展），任一命中即退出并在 drain.log 留一行终止记录。而队列里仍有积压完全正常：`until` 说的是「追平到 ≤N 条」，不是「清空」。只看 `ps` 的话，正常收工会被写成「飞轮崩了/被 kill 了」，进而触发不必要的重启或改脚本。

**证据**（session:01a0b2f3…，只读巡检，切片「命令 ↔ 结果」）：
- `ps -eo pid,command | awk '$0 ~ /evo-drain\.sh/ && $0 !~ /awk/ {print}'` → `=== 1. PS ===` 之后无任何行（无匹配）。
- `cat ops/log/drain.log` → 起跑行 `2026-09-18T01:47:28Z === drain 启动（until=5 budget=12h round-max=48 jobs=auto 门槛=50000B）===`；轮次行 `2026-09-18T03:28:07Z --- 第 1 轮结束：队列 71 → 70，净减 1 ---`（队列没清零，飞轮照跑）。
- 末条 assistant 的判定原文：`Verdict: the drain loop has STOPPED, not running.` + `ps matched nothing, and its own log records a clean stop: 04:36:46Z …` —— 用的正是「ps 空 + 日志终止记录」两条一致。
- 停止条件清单可核：`ops/bin/evo-drain.sh` 头部注释（含 `--until/--budget-hours/--max-empty` 默认值）。

**边界 / 反例**：
- `ps` 无匹配但日志**没有**终止记录（末行停在 `第 N 轮开始` / `等锁中`）→ 才该怀疑异常中断；此时先量机器负载与进程状态，别直接 kill（见 related `log-gap-is-not-process-hang-check-load`）。
- pattern 不是身份判据：同机有 `cp` 到别处跑的 drain/distill 副本时会命中同一 pattern（见 related `ps-script-name-match-hits-unrelated-copy`）。
- 「已收工」≠「活干完了」：收工后仍可能有队列积压与待重试的 fail 会话，报告里要把「进程已停止」与「还有多少没处理」分开写。

**失败信号**（未来命中即该想起本条）：
- 手上只有 `ps`（或只有日志）一条证据，却准备断言「drain 挂了 / 还在跑」。
- 看到进程消失 + 队列没清零，第一反应是「飞轮坏了」而不是「去读 drain.log 终止行」。
- 想 kill/重启一个「不见了」的 drain（它可能只是按预算/阈值正常收工了）。
