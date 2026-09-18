---
id: distill-start-done-pairing-measures-throughput
type: lesson
status: candidate
scope: project:evo-kernel
domain: evo-kernel
tags: [evo-distill, distill-log, 吞吐, 延迟, 巡检]
triggers:
  - "巡检 evo-distill 飞轮：想量化产出与单会话耗时，判断是不是变慢/卡住"
  - "distill.log 里几百行 start/done，想按某个时间窗口统计完成了多少"
  - "只看 done 条数或队列长度就判断飞轮健康（失败信号）"
  - "需要找出有 start 但没有 done 的会话"
  - "要给出飞轮在某窗口内的产出与延迟分布证据"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2f3-86b5-73b1-bdd8-c2dceaa1549e
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [distill-log-done-line-is-the-completion-ledger, awk-hhmm-threshold-matches-other-dates-inflating-progress, evo-queue-lists-no-status-column]
---

**主张**：量化 evo-distill 飞轮「跑得怎么样」要把 `distill.log` 的 `start <sid>` 与 `done <sid> — DISTILL_OK n` **按 sid 配对**：窗口内 start/done/fail 三个计数 + 每对 `done_ts − start_ts` 的分布 + 有 start 而没配到 done 的 unpaired 清单，三者一起报；只数 done 条数或看队列长度都会漏掉「开工多但拖着不收尾」这种坏状态。

**为什么**：配对同时回答三件不同的事——窗口内多少会话开工（start）、多少真正收尾（done）、单会话耗时分布（中位数就能把「飞轮变慢」和「卡死」区分开）。有 start 无 done 的会话从 done 计数里完全看不见，它们要么还在跑、要么被 kill/失败待重试，是巡检真正需要追的集合。

**证据**（session:01a0b2f3…，切片「命令 ↔ 结果」）：
- 命令：`python3 - <<'EOF'` 逐行解析 `ops/log/distill.log`，以 `W = "2026-09-18T03:28:00Z"` 为窗口收集 `starts`/`durs`，并按 `start/done/fail` 计数。
- 结果：`window >= 2026-09-18T03:28:00Z start=72 done=72 fail=0 paired durations n=72 median=2.85 min max=5.53 min unpaired start…` —— 该窗口 72 个会话全部收尾、零 fail、单会话耗时中位 2.85 分钟、最长 5.53 分钟；末段还输出了 unpaired（有 start 未配对 done）一项。
- 同次巡检的日志体量：`wc -l ops/log/distill.log` = `1008 ops/log/distill.log` —— 说明这是从千行日志里按窗口切出来的统计，不是手工数出来的。

**边界 / 反例**：
- 时戳必须整串比较（ISO 前缀，如 `$0 >= "2026-09-18T03:28"`）；只比 `HH:MM` 会把别的日期算进窗口（见 related `awk-hhmm-threshold-matches-other-dates-inflating-progress`，同一份日志上真踩过）。
- `done` 条数 ≠ 提案产出数：`done … — DISTILL_OK 0` 是正常结果（跑完但查重后零提案）；要算产出得另取 `DISTILL_OK` 后的 n。
- 失败会重试（`fail …（未标记，将重试）`），同一 sid 可能有多段 start→fail→start→done；配对时要知道一个 sid 可能出现多对。
- 本条的 `n=72 / median 2.85 min` 是**该窗口**的观测值，不是稳态指标；换窗口或改并发（`EVO_DISTILL_JOBS`）都会变。

**失败信号**（未来命中即该想起本条）：
- 报告里只有「完成了 N 个会话」，说不出这批花了多久、有没有开工未收尾的。
- 拿队列长度变化当吞吐指标（队列还受入库速率影响，净减可以 ≈0）。
- 统计窗口内完成数时没按日期整串过滤，数字明显偏大。
