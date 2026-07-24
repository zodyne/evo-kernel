---
id: agent-self-evolution-landscape
type: fact
status: validated
scope: global
domain: agent-self-evolution
tags: [survey, ace, reasoningbank, landscape]
triggers:
  - "agent 自进化/经验学习的方案选型"
  - "知识库与记忆框架对比"
  - "大厂对 agent 记忆的立场"
created: 2026-07-23
evidence: {helpful: 1, harmful: 0}
verified_by: human
source: "research:~/Dev/agent-evo"
last_verified: 2026-07-23
superseded_by: null
schema_version: 1
---
Agent 自进化分两路线：In-Weight（改参数，贵/不可审计）vs In-Context（改外部记忆，2025 后主流）。In-Context 的共性架构收敛为 ACE 三角：Generator→Reflector→Curator，增量 delta 更新防 context collapse；失败经验与成功经验同等蒸馏（ReasoningBank）。
工业界四立场：Anthropic 渐进工程（harness/skills/memory tool）、OpenAI 有界 agency（eval 飞轮+用户主权记忆）、Google 进化的是"解"非 agent（AlphaEvolve）、Microsoft 可治理编排（回避自我改写）。
**全文**：~/Dev/agent-evo/notes/01-05（29 论文 + 30 官方文章 + 蓝图 design/blueprint.md v2）。
