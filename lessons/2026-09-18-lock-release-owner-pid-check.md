---
id: lock-release-owner-pid-check
type: lesson
status: candidate
scope: global
domain: concurrency
tags: [lock, pid, trap, ownership, background-job]
triggers:
  - "给脚本的排他锁写 trap/EXIT 清理（无条件 rm -rf 锁目录）"
  - "进程退出后锁被删了，但删它的不是当时真正的持有者（失败信号）"
  - "同一批处理出现无锁并发：谁都没觉得自己抢了锁"
  - "锁被别的实例判过残留、清理并重建，原持有者随后退出"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4d2-e53f-7341-b816-247fbf0b3018
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [lock-heartbeat-long-job-mtime-stale]
---
**主张**：释放排他锁不能无条件 `rm -rf` 锁目录/文件——只要发生过「自己持锁期间锁被别人判残留、清掉并重建」，先退出的一方就会删掉**新持有者**的锁，此后系统进入「无锁并跑」。正确做法：获取锁时把 owner pid 写进锁内（`echo $$ > "$LOCK/pid"`），释放（trap/EXIT）时只在 `cat "$LOCK/pid" == $$` 时才删。

**为什么**：锁的归属必须可验证。「谁创建了锁目录」在文件系统里没有身份信息，所以任何实例都能删任何锁；一旦锁生命周期内发生过「清理—重建」，锁已经易主，旧持有者的清理逻辑若不校验身份就是无差别破坏。pid 文件把「持有者是谁」变成锁内可读的显式字段，让释放动作变成「删自己那把」而不是「删这个路径」。

**证据**（本会话产出，slice 显示 push `a7f8a1d..3dedd88`）：
- 修复 diff：`trap 'rm -rf "$LOCK"' EXIT` → `echo $$ > "$LOCK/pid"` + `trap 'if [ "$(cat "$LOCK/pid" 2>/dev/null)" = "$$" ]; then rm -rf "$LOCK"; fi' EXIT`。
- 桩测（slice「命令 ↔ 结果」）：`4a 自己持有 → 退出应删锁 → ✓ 已删`；`4b 运行中被别人接管（rm+重建，pid 变成别家）→ 退出不许动它 → ✓ 接管者的锁完好`。
- 与心跳修复同批提交：两缺陷叠加时，「按 mtime 判残留抢锁」（见 related `lock-heartbeat-long-job-mtime-stale`）与「退出删他人锁」会共同产出「无锁并发」的终态。

**边界/反例**：理论上 pid 会被复用，可能出现「别人的 pid 恰好等于自己」，但锁的存活窗口远短于 pid 回绕周期，实务可接受；要更严格可在锁内写 pid + 进程启动时间或随机 nonce。注意写入 pid 后要容忍失败（`|| true`），且读取失败（文件已被删）时应保守地**不删**锁——宁可留残留锁让下一轮判残留，也不要删掉可能属于他人的锁。
