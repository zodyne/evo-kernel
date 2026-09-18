---
id: log-gap-is-not-process-hang-check-load
type: lesson
status: candidate
scope: global
domain: ops
tags: [uptime, load-average, hang-vs-stall, polling, watchdog]
triggers:
  - "后台任务/轮询日志出现十几分钟空档，而正常应每分钟一行"
  - "准备按『日志停更』判定进程挂死并 kill 重启（失败信号：手上只有这一条证据）"
  - "自己的 sleep/轮询命令也被工具超时掐掉（失败信号：卡住的不只是目标进程）"
  - "无人值守监控要上报『任务疑似卡死』之前，先量机器负载"
  - "高并发后台任务期间，本机交互命令集体变慢"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b211-aaee-73b1-bdd8-c2cfeae4ad73
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [faulthandler-dump-traceback-later-hang, stop-condition-on-hour-scale-metric-is-not-a-stop-condition]
---

# 日志十几分钟空档 ≠ 进程挂死：先量机器负载与进程状态，别急着 kill

## 主张

被等待的进程停止写日志、并且**你自己的轮询命令也被超时掐掉**时，缺省假设应该是"机器被压住/外部命令变慢"，而不是"目标进程死了"。判据是机器级证据：`uptime` 的 load average 与 `ps -o stat,%cpu` 的状态。本会话在同一时段两个独立症状同时出现（日志断更 + 轮询命令超时），load 4.05，而目标进程 STAT 全为 `S`、日志随后自行恢复——若当时按"停更=挂死"处置（kill/重启），就是在错误的诊断上动刀。

## 证据（本会话，命令 ↔ 结果）

1. 轮询命令 `sleep 600; date -u; ps ...; tail drain.log`（工具 timeout 900s）→ `✗ Command timed out after 900 seconds`——**自己的 sleep 都没跑完**，说明卡的不只是目标进程。
2. `tail ops/log/drain.log`：断更前最后一行 `2026-09-18T02:31:47Z 等锁中（pid=86143 持有，队列仍 74 条）`；再取时首行已是 `2026-09-18T02:48:28Z 等锁中（…）`——空档 ≈ 17 分钟，而该脚本正常每 60s 追加一行。
3. 同一时刻 `uptime` → `10:43 up 8 days, 19:22, …, load averages: 4.05 2.79 2.30`。
4. `ps -o pid,ppid,stat,etime,%cpu,wchan,command -p 78769` → `78769 1 S 56:20 0.0 -`；同查 `86143,86155,86156` 亦为 `S`、`0.0`——没有 D/Z 态、没有僵尸。
5. 处置：只读观察 + 继续轮询，日志在空档后自行恢复追加，队列数字继续下降；全程未 kill/重启（这也让后续判定"净减"得以继续）。
6. 另一条解释方向未被排除也不能排除：drain 循环每轮调用 `evo queue`（Node CLI），该外部命令在高负载下也可能变慢——无论哪条，结论都是"机器级慢，不是任务死"。

## 边界 / 反例

- 反向也成立：`STAT=S` + load 高**不能**证明进程没死锁（睡眠等锁同样是 `S`）。要区分"等外部/变慢"与"死锁"，还需要它有没有活着的子进程、CPU 时间是否在增长（见 `related: faulthandler-dump-traceback-later-hang`）。
- 本会话只观测到一个空档样本（≈17 分钟）且已自行恢复；若空档持续、且 load 已回落，就该转向"进程真的卡住"的假设。
- 别把这条当"卡了也别管"的借口：长时间停更 + 恢复后没有产出，仍要按原判据判失败。

## 失败信号（未来命中即该想起本条）

- 还没量 `uptime`/`ps` 就准备 `kill` 一个"停更"的后台任务。
- 目标日志空档的同时，你自己在同一个 bash 调用里的 `sleep` 也被超时掐掉。
- 高并发后台任务（多 worker 蒸馏/批处理）期间本机命令集体变慢、日志时间戳出现秒级漂移。
