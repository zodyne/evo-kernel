---
id: deepseek-reasoning-effort-levels-mapping
type: fact
status: validated
scope: global
domain: harness-config
tags: [deepseek, reasoning_effort, pi, subagents, thinking, default-agents]
triggers:
  - "DeepSeek reasoning_effort 有哪些档位、medium/xhigh/minimal 怎么映射"
  - "pi 里设 medium 是不是等于 DeepSeek 默认档（high）"
  - "pi-subagents 子代理 thinking 默认 inherit 父会话，想改全局默认"
  - "想让主循环 max、子代理 high，必须用同名 .md 覆盖内置代理（general-purpose/Explore/Plan）"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-13-05-11-53-818-d7y0
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
related: []
---

# 主张

DeepSeek `reasoning_effort` 只有 low/high/max，默认 high；medium/xhigh 映射成 high，minimal→low。pi 里设 medium 等于 DeepSeek 默认档。

# 实测数字

- trivial prompt：high 28 / max 47 reasoning tok，差别在复杂步。

# 附：pi-subagents 的 thinking

pi-subagents 子代理 thinking 默认 inherit 父会话，无全局默认项；要主循环 max、子代理 high，必须用同名 `.md` 覆盖内置 general-purpose/Explore/Plan（定义在 `src/default-agents.ts`）。
