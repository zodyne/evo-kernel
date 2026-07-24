---
id: parallel-research-delegation
type: bullet
status: validated
scope: global
domain: orchestration
tags: [subagent, delegation, research]
triggers:
  - "多方向的大规模调研任务"
  - "要派多个子代理并行工作"
  - "写子代理任务描述"
created: 2026-07-23
evidence: {helpful: 4, harmful: 0}
verified_by: human
source: session:agent-evo-research
last_verified: 2026-07-23
superseded_by: null
---
多方向开放调研的高效模式：≤4 个 worker 并行、每方向范围收窄、任务描述完全自包含（子代理是隔离上下文：写清目标/路径/约束/产出格式/验证方法）、候选清单标注"先验证再深入"（候选 id 可能错）。
**证据**：agent-evo 两轮研究 7 个 worker 全部成功，29 论文 + 30 文章均校验有效。
**边界**：worker 响应慢（单步 30-90s）属正常；同一任务失败 2 轮即熔断回主上下文。
