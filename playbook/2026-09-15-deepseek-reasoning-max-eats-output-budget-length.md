---
id: deepseek-reasoning-max-eats-output-budget-length
type: lesson
status: validated
scope: global
domain: llm-tooling
tags: [deepseek, reasoning, max-tokens, nanoradar, finish-length, root-cause]
triggers:
  - "报 maximum output token limit / finish_reason=length 但回复正文是空的"
  - "配 deepseek-v4 系 reasoning 模型 max_tokens 时要不要给思考留正文余量"
  - "reasoning_effort=max/high 后回复只剩思考没有正文"
  - "usage 里 output 全被 reasoning 吃掉、completion 为 0"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a3ff-16b7-73aa-b447-07d4b5ec2022
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [deepseek-length-zero-body-disable-thinking-recover, pi-context-counts-reasoning-content]
---

# deepseek reasoning 模型的 max_tokens 是「思考+正文」共享预算，effort 高时思考吃光预算 → 0 正文 + finish=length

**主张**：deepseek-v4-flash（NovaSky 网关）这类 reasoning 模型，`max_tokens` 是思考（reasoning/CoT）与正文的**共享输出预算**，不是仅限正文。当 `reasoning_effort=max` 且任务触发长 CoT 时，思考可吃满整个预算，导致正文 0 字、`finish_reason=length`——用户看到的正是 pi 报的 `Error: Model stopped because it reached the maximum output token limit`。

**为什么**：根因是预算共享机制，不是上下文溢出。事故现场 `usage.output=32768, reasoning=32768`（100% 进了思考、正文 0），且该条 length 回复的 output 占该会话全部 output 的 89.9%。它和「context 溢出」是两回事：pi 源码用 `stopReason==="length" && usage.output===0 && input+cacheRead >= contextWindow*.99` 单独判 context 溢出，而这里是 max_tokens 被思考吃光。配 reasoning 模型时若只按「正文需要多少 token」设 max_tokens、不给 CoT 留余量，就会踩中。

**边界**：`effort=max` 不是每次都吃光——短任务 CoT 短、预算够时正常收尾（实测 `effort=max` + cap=32768 → reasoning=83 / output=85 / finish=stop）。触发条件 = **长 CoT 任务 + cap 不够**，二者同时满足才 0 正文。cap 越小越易复现（cap=800 时打印 1..15000 这个长 CoT 任务 3/3 命中 reasoning=800、正文 0、finish=length）。

**证据**：slice 内命令↔结果成对佐证——事故现场 `usage:{input:4852, output:32768, reasoning:32768}`；标定实验 cap=800 打印 1..15000 三次全中「思考吃光、正文 0 字」；A/B/A 同 prompt 只改 max_tokens 复现；对照组 `effort=max` + cap=32768 得 `reasoning 83 / output 85 / stop`。
