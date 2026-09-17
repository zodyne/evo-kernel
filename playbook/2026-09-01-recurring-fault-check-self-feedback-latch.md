---
id: recurring-fault-check-self-feedback-latch
type: lesson
status: validated
scope: global
domain: system-governance
tags: [自反馈环, 闩锁, 重复性故障, 触发条件, 空跑, gbrain]
triggers:
  - 重复性故障反复发生，优先查自反馈环(状态→触发→状态)
  - 触发频率异常 + 触发条件单调增长（闩锁指纹）
  - 定时任务每隔固定时间空跑、吃 CPU
  - 改判据前是否需要回放历史数据验证新判据
  - gate since/debt 单调增长导致触发条件永久为真
created: 2026-09-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-01-08-55-38-442-7sqs
last_verified: 2026-09-01
superseded_by: null
schema_version: 1
related: [self-registration-hook-self-pollution-loop]
---

# 重复性故障优先查自反馈环(状态→触发→状态)

重复性故障优先查自反馈环(状态→触发→状态)。

## 证据

FAILED→STAMP不推进→gate since/debt单调增长→触发条件永久真→每40min空跑34%CPU。

## 判据 / 边界

闩锁指纹=触发频率异常+触发条件单调增长；改判据前先回放历史数据验证新判据。
