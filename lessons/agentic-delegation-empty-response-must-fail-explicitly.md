---
id: agentic-delegation-empty-response-must-fail-explicitly
type: lesson
status: candidate
scope: global
domain: agent-delegation
tags: [mcp, delegation, orchestration, error-handling]
triggers:
  - "写把任务委派给外部模型执行的 MCP 代理/桥（Claude 编排、kimi/glm 当手脚）"
  - "编排-执行分离架构里设计执行侧的返回判定与重试/降级策略"
  - "委派工具调用显示成功但返回内容为空，编排方拿空结果继续走（失败信号）"
  - "评审 agentic 代理代码的错误处理路径"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:019fb1f9-a81e-764d-8811-87dd56da1cc6
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [agentic-search-tool-value-is-truncation-not-capability]
---

**主张**：编排-执行分离的委派架构（编排方出方案+审核，外部模型当执行手脚）里，执行侧的 **agentic 空响应必须显式判为失败**并触发重试/降级，绝不能当成功返回——否则编排方拿到空结果误以为成功，错误沿链路静默放大，整个"编排-审核"模式不成立。

**证据**：会话对 graph-lab 943 行的 `multi_model_mcp.py`（把任务委派给 kimi/glm 等外部模型的 MCP 桥）做代码评审，按"Claude 当大脑、外部模型当手脚、token 消耗压在外部侧"的目标重排优先级后，将"agentic 空响应被当成功返回"列为**直接威胁该模式成立的最优先问题**（H3）。

**边界**：本条是人审（代码评审）结论，未附最小复现命令的输出；具体判空口径（空字符串/只有 tool call 无文本/白名单字符）与重试次数需按各自实现定。注意与 MCP 工具返回值"截断摘要"设计区分：截断是有意的信息压缩，空响应是无意的失败，两者判定逻辑别混在一起。
