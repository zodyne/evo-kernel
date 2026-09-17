---
id: pi-context-counts-reasoning-content
type: fact
status: validated
scope: global
domain: pi-harness
tags: [pi, reasoning, reasoning_content, deepseek, context, thinking-level]
triggers:
  - "pi 上下文增长快，想知道 reasoning 是否计入 input"
  - "DeepSeek requiresReasoningContentOnAssistantMessages / 同 turn 工具链回传 reasoning_content"
  - "thinking level 对压缩频率和每步耗时的影响"
  - "max/medium/off 等级下 reasoning 占输出比例（59-70%、少 30-45%、归零）"
  - "每步思维链计入后续所有步的 input 直到压缩（失败信号：上下文暴涨）"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-13-02-03-55-633-h7az
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
related: []
---

# 主张

pi 上下文增长里 reasoning 也算：DeepSeek 同 turn 工具链要求回传 `reasoning_content`（`requiresReasoningContentOnAssistantMessages`），每步的思维链计入后续所有步的 input，直到压缩。

# 实测数字

- max 等级 reasoning 占输出 59-70%，medium 每步输出少 30-45%（同日对比）。
- off 才真正归零（`thinking:{type:disabled}`）。
- thinking level 不改变单次压缩耗时，只改变压缩频率和每步耗时。
