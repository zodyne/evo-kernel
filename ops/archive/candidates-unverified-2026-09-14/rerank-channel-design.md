---
id: rerank-channel-design
type: lesson
status: candidate
scope: global
domain: retrieval
tags: [rerank, recall, small-model]
triggers:
  - "recall 召回质量差"
  - "实现 P1.5 rerank 通道"
  - "grep/triggers 漏召"
created: 2026-07-23
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: blueprint:v2 §6
last_verified: 2026-07-23
superseded_by: null
---
设想（待 P1.5 验证）：recall 增加小模型 rerank 通道——把 manifest 全量一行摘要（id+claim+triggers）喂一次小模型调用做相关性筛选，成本可忽略、召回质量应远超纯词匹配。
**待验证**：真实命中率提升幅度；endpoint 配置缺失/调用失败时必须静默降级回 P1 通道（fail-open）。
**判据**：注入精度（对账的「注入但无关」占比）对比 P1 基线。
**形态 B（2026-07-23 已实现）**：主 agent 即大模型精筛器——`evo candidates`（粗筛清单）+ `evo get --ids`（拉全文），零额外模型调用、无 hook 超时风险。若 agentic 模式命中率足够，P1.5 内嵌 rerank 可能被跳过。CLI 内嵌大模型不推荐：成本/延迟/key 管理 + hook 链路 fail-open 风险。
