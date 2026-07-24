---
id: episode-agent-evo-research
type: episode
status: validated
scope: global
domain: research-methodology
tags: [episode, agent-evo, research, blueprint]
triggers:
  - "回顾 agent-evo 研究项目"
  - "Evo-Kernel 设计的来源"
created: 2026-07-23
evidence: {helpful: 1, harmful: 0}
verified_by: human
source: session:agent-evo-research
last_verified: 2026-07-23
superseded_by: null
schema_version: 1
---
2026-07-22~23 完成两轮独立调研（不从 GBrain）：① 前沿调研：29 篇论文（自进化/记忆RAG/经验学习/综述四方向，7 worker 并行）；② 工业界调研：30 篇官方文章（Anthropic/OpenAI/Google/MSFT）。产出 ~/Dev/agent-evo/{papers,articles,notes,README.md}。
随后产出 Evo-Kernel 绿地设计（design/blueprint.md），独立评审 11 条全部成立 → v2。关键转折：计数回路改 distill 离线对账、triggers 字段解决词汇失配、fail-open 第一原则、目录即状态机。
**教训**：候选 arXiv id 错 3 个、SessionStart 拿不到 prompt——见 playbook 对应条目。
