---
id: config-health-claim-needs-full-cycle-verification
type: lesson
status: validated
scope: global
domain: research-methodology
tags: [配置健康, 完整周期, 验证状态, 风险陈述, gbrain]
triggers:
  - 声明配置/系统健康前没确认该配置跑过至少一轮完整周期
  - 唯一 OK 的一轮跑在旧配置下（失败信号）
  - 用「我的操作零破坏」代替「系统无风险」
  - 风险陈述没有区分自身操作层与系统状态层
  - 换模/改 budget/cadence 后直接宣布健康
created: 2026-09-01
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-09-01-09-16-55-887-cnh8
last_verified: 2026-09-01
superseded_by: null
schema_version: 1
related: []
---

# 声明配置/系统健康前必须确认该配置已跑过至少一轮完整周期验证

声明配置/系统健康前必须确认该配置已跑过至少一轮完整周期验证；'我的操作零破坏'不等于'系统无风险'——风险陈述须区分自身操作层与系统状态层。

## 证据

2026-09-01 案例:gbrain 换模+token 65536+budget 20+cadence 改动后零完整轮次验证,唯一 OK 轮跑在旧配置下,而审查方只陈述了自身零写操作,未覆盖系统真实验证状态。
