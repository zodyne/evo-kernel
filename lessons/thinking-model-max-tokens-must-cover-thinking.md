---
id: thinking-model-max-tokens-must-cover-thinking
type: lesson
status: candidate
scope: global
domain: llm-ops
tags: [max-tokens, thinking, stop-reason, kimi, api-debugging]
triggers:
  - "思考型模型返回空文本/零输出，stop_reason=max_tokens（失败信号）"
  - "区分 LLM 调用失败是 token 预算耗尽还是传输层中断"
  - "给带 thinking 的模型设 max_tokens，只按最终答案长度估算"
  - "连接中断类错误想靠调 token 参数修复"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:06d00000
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [kimi-thinking-budget-no-help-for-disconnect]
---

# 思考型模型的 max_tokens 必须包含思考预算，否则零文本输出

**主张**：带 extended thinking 的模型，`max_tokens` 预算是**思考 token + 输出 token 共享**的——预算只按答案长度设（如 4096/16000），密集推理任务会把预算全被 thinking 吃光，最终 `stop_reason=max_tokens` 且**一个字没剩给答案**。修法：按"思考 + 答案"总和设（实测 16000→32000 解决）；agentic 循环路径也要查（当时 `_run_anthropic_loop` 只有 4096，是没暴露的隐患）。

**边界（先分失败类型再调参）**：这与传输层连接中断（`RemoteProtocolError: Server disconnected`，约 130–175s 被掐）是**不同性质**的失败——中断只与服务端耗时/任务复杂度相关，调任何 token 参数都无效（对照实验证实，见 related）。调参前先看错误是 `stop_reason=max_tokens` 还是连接异常。

**证据**：session 06d00000，kimi 代码审查任务 16000 token 全被 thinking 吃光；受控 A/B 实验排除 thinking.budget_tokens 对中断的作用。
