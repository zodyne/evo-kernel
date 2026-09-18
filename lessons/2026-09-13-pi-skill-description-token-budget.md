---
id: 2026-09-13-pi-skill-description-token-budget
type: lesson
status: candidate
scope: global
domain: pi
tags: [pi, skill, token, context, budget]
triggers:
  - "评估要不要装一个带一堆 skill 的 pi 包"
  - "担心 skill 包把启动上下文撑大"
  - "多个 pi 包之间比较上下文开销"
  - "装包后上下文占用异常增大，想定位来源（失败信号）"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a099a8-07d2-766c-b240-9eaed5f6ca6d
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
---

**主张**：评估 pi skill 包的启动注入成本，按"模型可见 skill 的 description 字符数 ÷ 4 折算 token"统计即可；带 disable-model-invocation 标志的隐藏 skill 只有 /skill: 命令能用，单独计。实测量级是几百 token，不构成装载负担。

**为什么**：装包决策常被"skill 太多会不会撑爆上下文"劝退；一个十几行脚本（遍历 skills/**/SKILL.md，取 description 字符数，按 dmi 标志分组）就能把争论变成数字。

**反例/边界**：本口径只统计 description 字符数；skill 正文是否/何时进上下文是另一个问题（本会话对"pi 启动时把 skill 的 name+description 注入"这条断言做对抗核查时发现反例、主张被弱化），不要拿本条数字去背书正文注入行为。

**证据**（session:01a099a8-07d2-766c-b240-9eaed5f6ca6d）：脚本实测 pi-gauntlet 17 个 skill / 3570 字符 description，其中模型可见 13 个 ≈616 token、隐藏 4 个 ≈275 token；gentle-pi 13 个 / 1762 字符。可见 skill 的注入成本为百 token 级。
