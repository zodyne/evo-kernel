---
id: launchd-silent-output-disk-only
type: lesson
status: validated
scope: global
domain: launchd
tags: [launchd, 定时任务, 静默, 落盘, 后台任务, 验证]
triggers:
  - "检查/验证一个 launchd 定时任务是否在跑、是否产出了结果"
  - "定时任务到点了但不知道它到底有没有执行"
  - "后台兜底任务跑完没有任何提示，不确定要不要手动确认产出"
  - "launchd 脚本任务看起来没反应，怀疑它静默失败或压根没触发"
  - "想知道某个后台任务『送达』到哪里，结果发现没有任何消费者"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0ad8d-d7a1-764c-a77e-5170e29d623f
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [launchctl-list-print-diagnose-job, launchd-log-utc-timezone-trigger-check]
---
launchd 后台定时任务（LaunchAgent 里的兜底/脚本类任务）是静默的：跑完即消失，没有桌面通知、没有邮件、也没有任何下游消费者，产出只落盘；要确认它是否触发、是否产出，唯一的"送达"是主动去读落盘文件，别等任何通知。

evo-kernel 的 com.evo.distill（每日兜底蒸馏，清 SessionEnd 漏掉的积压）就属此类：`launchctl print` 显示 `state = not running`（瞬时任务，跑完即消失），plist 里只是一次 shell 脚本调用、无任何通知/上报机制；本轮"检查 evo 是不是 14:30 触发"最终结论就是"不会有人告诉你——它是静默的，结果只落盘，你得自己去读 ops/proposals/*.md、distill.log、队列、锁文件"。

边界：只适用于纯落盘、无通知机制的 LaunchAgent 脚本/兜底任务；若任务自带上报（如 deliver 到 messaging 网关）则不适用。验证产出的顺序建议按落盘面逐个看：成果物目录 → 日志 → 队列 → 锁文件。
