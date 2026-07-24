---
id: recall-dedup-only-after-injection
type: lesson
status: candidate
scope: global
domain: retrieval
tags: [dedup, recall, hook, edge-case]
triggers:
  - "recall/hook 注入逻辑的去重实现"
  - "同 session 只注入一次的副作用"
  - "空结果写日志影响后续判断"
created: 2026-07-23
evidence: {helpful: 1, harmful: 0}
verified_by: test
source: session:evo-kernel-bootstrap
last_verified: 2026-07-23
superseded_by: null
---
「同 session 去重」的判断必须基于**实际注入过条目**（ids 非空），而非「调用过 recall」。空命中（无相关经验）若也占去重名额，该 session 后续出现真相关任务时将永远失去注入。
**证据**：evo CLI 首版踩中此 bug，测试"天气→hook 配置"序列发现第二次不注入；修复为 injectedSessions 仅收集 ids 非空的 session。
