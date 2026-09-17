---
id: reconcile-claim-with-own-timeseries
type: lesson
status: validated
scope: global
domain: research-methodology
tags: [时间序列, 对账, 趋势断言, 实查, 结论作废]
triggers:
  - 写趋势/状态断言前没有与自己已采的时间序列对账
  - 序列方向与结论矛盾，结论仍被保留（失败信号）
  - 数据在手却没读，把增长写成稳定（实查类错误）
  - 想区分「没查就下结论」和「查了没读」两类错误
  - 快照 450→476→579 在涨却写稳定不涨
created: 2026-09-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-01-09-14-51-121-dc5k
last_verified: 2026-09-01
superseded_by: null
schema_version: 1
related: [coverage-denominator-is-a-moving-target]
---

# 写趋势/状态断言前，先与自己已采的时间序列对账

正交于'依据标注来源'的第二条规则:写趋势/状态断言前,先与自己已采的时间序列对账;序列方向与结论矛盾时,结论作废重查。

## 证据

2026-09-01 案例:三次快照 450→476→579 在涨却写'稳定不涨'——这是'实查'类错误(数据在手没读),来源标注规则挡不住,必须补时间序列对账这条正交规则。

## 边界

旧规则管'没查就下结论',新规则管'查了没读'。
