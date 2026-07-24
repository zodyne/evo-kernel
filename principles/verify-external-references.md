---
id: verify-external-references
type: principle
status: validated
scope: global
domain: meta
tags: [verification, trust, principle]
triggers:
  - "使用任何外部提供的 id/URL/配置字段名"
  - "凭记忆写技术细节"
  - "API 参数/字段名不确定"
created: 2026-07-23
evidence: {helpful: 5, harmful: 0}
verified_by: human
source: session:agent-evo-research
last_verified: 2026-07-23
superseded_by: null
schema_version: 1
---
任何外部 id、URL、配置字段名、API 参数，**使用前必须验证**，不得凭记忆或传闻直接使用。
**为什么**：一次任务中 3 个 arXiv id 错误 + 1 处 Claude hook 机制事实错误，若未验证直接落地，会造成静默失败（下错论文）或莫名失败（注入不触发）。
**边界**：验证成本高的可标注"待验证"降级使用，但关键路径（写入配置、批量下载、对外交付）必须先验证。
