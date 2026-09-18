---
id: stop-condition-on-hour-scale-metric-is-not-a-stop-condition
type: lesson
status: validated
scope: global
domain: agent-orchestration
tags: [background-agent, stop-condition, polling, scheduling, subagent]
triggers:
  - "起一个后台 agent/轮询任务去等另一件事完成"
  - "把等待条件写成『那个进程结束』这类以小时计的判据"
  - "后台 agent 空转很久、反复轮询却始终不满足完成条件"
  - "要给『等 X 完成后处理 Y』做编排（轮询 vs 一次性定时）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b1aa-8483-73b1-bdd8-c2cc6d20a4c5
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [open-ended-task-plus-tools-has-no-stop-condition]
---

# 停止条件的**时标**必须与预期完成量级同阶：挂在小时级判据上等于没有停止条件

## 主张

给后台/等待型 agent 设停止条件时，除了「条件写没写」，还要问一句：**这个条件在多长时间内能成立？**若把条件挂在另一个**以小时计**的进程上（"等那个循环结束"），而预期完成量级只有几十分钟，那条件在预期时间内根本不可能成立 —— agent 只能无意义地反复轮询，直到耗尽耐心或预算。**判据的时标 ≈ 预期完成时间**才算有效停止条件。

代替做法：按**预期 ETA** 排**一次性**检查，而不是按固定间隔长期轮询。已知 ETA ≈ 90 分钟时，一次 `+90m` 的一次性唤醒与十几次轮询得到的信息量相同。

## 为什么

2026-09-18 实测：为等一个蒸馏轮次结束起了一个后台 watcher。中途那个轮次被换成「连续跑轮次直到队列追平」的循环，而该循环的预算是 **12 小时**；watcher 的完成判据也随之被指定为「等那个循环结束」。结果它在 **2.4 小时 / 22 次工具调用 / 26k token** 里反复轮询，而完成条件在预期时间窗内**不可能**成立——它唯一能做的事就是等下去。

判据本身没写错（"循环结束"确实是正确的完成信号），错的是**时标**：把一个 12 小时量级的判据，配给了一个 1.5 小时量级的任务。

## 反例 / 边界

- 轮询本身不是错的。**事件密集且不可预测**时（几秒到几分钟量级、随时可能发生），短间隔轮询是正确选择；病在"轮询间隔 × 预期等待"这个乘积大到没有信息增量。
- 也不要走反向极端：把一次性检查排得太早，同样只是多一次无效唤醒，还得再排一次。
- 判据时标与 ETA 都不确定时，先量化 ETA（实测吞吐 × 待处理量），再定时标——本例就是先量出「约 53 条/小时、队列 62 条 ⇒ 约 1.2 小时」之后才换掉轮询的。
- 与 `open-ended-task-plus-tools-has-no-stop-condition` 互为镜像：那条讲**没有**停止条件会失控；本条讲**有**停止条件但时标错位，等于没有。两者都会表现为"agent 一直挂着"。
