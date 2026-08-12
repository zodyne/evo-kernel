---
id: claude-code-subscription-model-routing-facts
type: lesson
status: candidate
scope: global
domain: claude-code
tags: [claude-code, subscription, model-routing, context-rot]
triggers:
  - "Pro 订阅能不能接第三方模型"
  - "子 agent model 字段填第三方模型"
  - "长会话质量下降是不是缓存的锅"
  - "prompt 缓存会不会让模型变笨"
created: 2026-07-23
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:4697eb23
last_verified: 2026-07-23
superseded_by: null
schema_version: 1
---

**主张**：两条已核实的 Claude Code 事实：① 登录 Pro/Max 订阅（OAuth）后只能路由 Anthropic 自家模型，主模型和子 agent 都不能切第三方——`.claude/agents/*.md` 的 `model` 字段只认 opus/sonnet/haiku/inherit 别名；要用第三方模型只能整个 harness 改走 API key/第三方端点。② Prompt 缓存不影响输出质量（同样输入命中与否结果相同）；长会话质量下降的真因是 context rot（注意力稀释）、自动 compaction 丢细节、工具输出噪音堆积。

**为什么**：两个都是高频误判——把「会话变笨」归因缓存会导向清缓存这种无效动作；有效动作是缩短会话、切分任务、把关键约束在压缩后重申。

**边界**：① 是 2026-07 时点的订阅形态，harness 更新可能放开，用前复核；② compaction 丢失的具体内容不可预知，关键决策应落盘到文件而非只留在对话里。

**证据**：2026-07-23 问答会话，两条结论均给出机制解释。
