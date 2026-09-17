---
id: diagnose-by-measured-output-not-proxy-status-word
type: lesson
status: validated
scope: global
domain: system-governance
tags: [诊断, 代理指标, 状态字, FAILED, 产出表, gbrain]
triggers:
  - 诊断组件失效时先看 wrapper 状态字/计数器（失败信号：代理指标当事实）
  - 把 FAILED 闩锁读成零产出、建议切除组件
  - 计数器 0/0 的分母与语义还没验证就下结论
  - 判据≠事实，需要直接测量产出
  - 判断一个组件是否真的没产出
created: 2026-09-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-01-08-55-38-402-4vzy
last_verified: 2026-09-01
superseded_by: null
schema_version: 1
related: [launchd-silent-output-disk-only]
---

# 判据≠事实：诊断组件失效先直接测量产出

判据≠事实：诊断组件失效先直接测量产出；wrapper 状态字(FAILED)与计数器(0/0)是代理指标，分母与语义必须先验证。

## 证据

gbrain dream 误诊案：把 FAILED 闩锁读成'零产出'建议切除，实际每日产出 127 atoms/312 concepts，正确路径是五态回归+直接读产出表。
