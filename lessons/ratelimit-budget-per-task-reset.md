---
id: ratelimit-budget-per-task-reset
type: lesson
status: candidate
scope: global
domain: agent-tooling
tags: [rate-limit, budget, counter, agent-loop]
triggers:
  - "给 agent 工具加限流/预算"
  - "计数器用函数属性做全局状态"
  - "限流永远不重置"
  - "每个任务 N 次变成进程生命周期 N 次"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:5f8dee58
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
---

**主张**：给 agentic 工具加限流/预算时，不要用函数属性（`func.count`）或模块级全局做计数器——它从不重置，实际语义是「进程生命周期内最多 N 次」而非「每个任务 N 次」。预算要显式创建（如字典），在每次任务入口（如 `run_agentic_task`）重置。

**为什么**：两个外部模型（kimi、glm）各自独立给出的示例限流代码犯**同一个 bug**——函数属性全局计数器。多模型一致也可能是一致地错，审查时不能因「两边都这么写」就放行。

**边界**：进程级总量熔断（防失控）是另一层语义，可与每任务预算并存，但要分开实现、各自命名清楚。

**证据**：2026-07-30 pal 仓库 multi-mode 增强会话，web_search 工具限流审查时绕开该坑并端到端验证。
