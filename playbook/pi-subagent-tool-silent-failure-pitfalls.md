---
id: pi-subagent-tool-silent-failure-pitfalls
type: bullet
status: validated
scope: global
domain: pi-agent
tags: [pi, subagent, parallel, chain, silent-failure]
triggers:
  - "用 pi subagent 工具（官方 example 扩展）派 parallel/chain 任务"
  - "项目级 .pi/agents 加载不到、报 Unknown agent"
  - "parallel 扇出的大产出回流给模型时被截断"
  - "chain 的下一步拿不到上一步输出"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-08-01-22-59-40-832-krkr
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [agentic-delegation-empty-response-must-fail-explicitly]
---
pi subagent 工具有三个静默失效坑（源码核实），全部不报错、表现为"配置没生效"：

1. **`agentScope` 是顶层参数**，不是 tasks/chain 元素的字段——写进 task 元素是 unknown field 被静默忽略、回退默认 user scope，导致项目级 `.pi/agents` 加载不到、报 Unknown agent。
2. **parallel 模式每个任务回流给模型的输出上限 50KB**（`PER_TASK_OUTPUT_CAP` 截断；single/chain 不截断）——并行扇出的大产出必须落 `_workspace` 文件，不能只靠回流文本。
3. **chain 任务文本忘写 `{previous}` 占位符**，上一步输出被静默丢弃、不追加。

**另**：项目级 agent 的 UI 确认仅交互模式（`ctx.hasUI`）；headless `-p` 直接执行，`confirmProjectAgents: false` 可跳过交互确认。

**边界**：三条都是"静默"失败——无报错无警告，只能从结果反推；排查顺序先核参数位置，再核输出体量，再核占位符。
