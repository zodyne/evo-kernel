---
id: launchd-log-utc-timezone-trigger-check
type: lesson
status: validated
scope: global
domain: launchd
tags: [launchd, 时区, utc, 日志, 定时任务, grep]
triggers:
  - "判断定时任务/launchd 是否在某个本地时刻触发（如『下午 2:30 有没有跑』）"
  - "按本地时间 grep 日志却一条都找不到，怀疑任务没触发"
  - "排查 launchd 任务触发时刻，日志里时间戳和本地对不上"
  - "要给落盘日志按触发时段做 grep 统计，先要确认日志时区"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad8d-d7a1-764c-a77e-5170e29d623f
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [launchctl-list-print-diagnose-job, launchd-silent-output-disk-only]
---
判断 launchd/定时任务是否在某本地时刻触发时，先确认落盘日志时间戳的时区再 grep：这类日志通常是 UTC（`T...Z` 后缀），直接按本地时刻（如 `T14:3x`）grep 会落空，要换算成 UTC 再 grep（CST = UTC+8，14:30 CST → 06:30 UTC）。

本轮查"evo 是不是 14:30 触发"时，`date` 显示本地 `CST 2026`，但 distill.log 条目是 `2026-09-15T23:56:47Z`（UTC），因此正确 grep 是 `T06:(2|3|4)`（= CST 14:2x-14:4x）；旧档 03:30 CST 则对应 `T19:(2|3|4)`（= 19:30 UTC），两段命令注释明确写明了这层换算。

边界：只适用于日志以 UTC/Z 后缀落盘的情况；若脚本显式写本地时间或带 `+08:00` 偏移则不适用，动手 grep 前先 `head` 一眼日志时间戳格式确认时区。CST 到 UTC 是 +8 小时（减 8 得 UTC），方向别搞反。
