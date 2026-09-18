---
id: awk-hhmm-threshold-matches-other-dates-inflating-progress
type: lesson
status: validated
scope: global
domain: log-analysis
tags: [awk, log-filter, time-comparison, progress-stats, false-positive, dashboard]
triggers:
  - "用 `awk '$2 >= \"HH:MM\"'` 这类只比较时间字段的方式过滤跨天日志"
  - "统计『某个时间点之后完成了多少』却算出比实际大一个量级的数（失败信号）"
  - "日志行形如 `2026-08-24T19:40:08Z done … — DISTILL_OK 0`，想只看当天某时刻之后的记录"
  - "汇报进度/画曲线前要按时间窗口裁剪日志"
  - "awk 过滤结果里出现明显更早日期的行（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae1e-1763-764c-a77e-51771fbd8c10
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# 只比 `HH:MM` 的 awk 过滤会混进其他日期，进度统计被放大一个量级

**主张**：`awk -F'[ TZ]' '$2>="11:45"'` 只比较了**时分秒**字段，没有比较日期字段。字符串比较下"任何日期"的 `19:40` 都 ≥ `11:45`，于是 8 月的旧行也会被选中。跨天日志必须先锁日期，再做时间比较：`$1=="2026-09-17" && $2>="11:45"`；最稳的是用同一 ISO 格式的整行前缀比较 `$0 >= "2026-09-17T11:45"`。

**证据（2026-09-17 本机）**：
- 过滤命令 `awk -F'[ TZ]' '$2>="11:45" && /DISTILL_OK/' ops/log/distill.log | tail -12` 的输出首行就是 `2026-08-24T19:40:08Z done 5aa10f40-adb9-4bed-8289-12dc80f24037 — DISTILL_OK 0` —— 8 月 24 日的行被 9 月 17 日的阈值选中。
- 同一会话据此汇报的 `36 会话 / 59 提案` 随后被自己复查推翻，末条 assistant 原话：`我上一条统计里的「36 会话 / 59 提案」是错的 —— awk 把 8 月的旧日志行（2026-08-24T19:40 这类时间串 ≥ 11:45）也算进去了`，真实是"重启后完成 **1** 个会话"。

**做法**：过滤带日期的时间窗口，写成 `awk -v d="$(date +%F)" -F'[ TZ]' '$1==d && $2>="11:45"'`；或保留完整 ISO 前缀做整行比较。汇报数字前抽 2~3 条命中行肉眼核对日期。

**边界**：`-F'[ TZ]'` 把 ISO 串切成 `$1=日期`、`$2=时间`；日志前缀换成别的格式（本地时间、无 `Z`、带毫秒）时切分位置会变，应先确认格式再用整行比较。
