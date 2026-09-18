---
id: lock-heartbeat-long-job-mtime-stale
type: lesson
status: candidate
scope: global
domain: concurrency
tags: [lock, mtime, heartbeat, background-job, watchdog]
triggers:
  - "给后台长任务/批处理实现基于 mtime 的残留锁判定（看门狗定时清锁）"
  - "长任务跑了几小时，另一个实例也启动了，两边同时写同一批产物（失败信号）"
  - "机器休眠/挂起把墙钟拉长后，自己的锁被判残留、被第二实例接管"
  - "无人值守的后台任务出现实例并跑，但日志里没有任何报错"
  - "锁目录 mtime 很久没变，但持有者其实还活着"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4d2-e53f-7341-b816-247fbf0b3018
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [lock-release-owner-pid-check]
---
**主张**：用锁文件的 mtime「够不够新」来判锁是否残留，对**长期运行**的持有者是错误判据——作业跑几小时（或机器休眠把墙钟拉长）后锁的 mtime 同样会变旧，看门狗会据此把活着的实例判成残留、清锁并放第二个实例进来，两边并跑且不报错。持有者必须在工作/等待循环里**持续 `touch` 锁做心跳**，让「我还活着」成为显式可观测的证据；mtime 只保留作「持有者已死」时的辅助残留判据。

**为什么**：mtime 是「最后一次改动」的代理信号，不是「持有者存活」的事实。残留判定的本质问题是「持有者还活着吗」，而 mtime 旧既可能是持有者死了，也可能是持有者活得好好的只是没动锁。心跳把这两者分开：活实例持续刷新 mtime，死实例自然停止刷新、锁随之变旧被清理。

**证据**（本会话产出，slice 显示 push `a7f8a1d..3dedd88`）：
- 实测（9/15 过夜）：蒸馏实例跑到 5.5h（休眠把墙钟拉长）→ 看门狗按 120min 阈值判其为残留锁、清锁并发起第二实例 → 两实例并跑 2.5h，全程无报错。
- 修法：等待循环内加 `touch "$LOCK"`（注释原文：活着的长会话不该被别的实例按 mtime 误判为残留锁）。
- 桩测（slice「命令 ↔ 结果」）：`残留锁（mtime 2 天前）应被清理并继续 → ✓ 判残留并清理`；`新鲜外来锁（活实例）应 skip 且不动它 → ✓`。

**边界/反例**：心跳间隔必须显著短于残留阈值（本例阈值 120min、每 5s 一跳，余量充足）；心跳只解决「活着但 mtime 旧」，死进程的锁仍要靠 mtime/pid 判残留后清理——被 SIGKILL 的持有者停止心跳、锁变旧并被清理，是期望行为而非缺陷。若锁的持有者是睡眠中的机器，应改用「带 TTL 的显式租约 + 续租」而不是依赖文件系统时间戳。
