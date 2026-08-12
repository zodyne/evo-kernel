---
id: kimi-thinking-budget-no-help-for-disconnect
type: lesson
status: candidate
scope: global
domain: llm-api
tags: [kimi, moonshot, thinking, disconnect, falsified-hypothesis]
triggers:
  - "Kimi/Moonshot API 复杂长 prompt 报 RemoteProtocolError: Server disconnected"
  - "想靠显式传 thinking.budget_tokens 限制推理长度来缓解断连/超时"
  - "LLM API 断连，手头有多个候选缓解手段不知道哪个有效"
  - "调 thinking/推理参数前，先假设它能减少生成耗时从而避开断连（失败信号：假设未实测）"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:06d00000-c5a0-4247-9e4a-de361d19d25e
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [llm-api-proxy-timeout-wall-retry-futile, nonstream-ttfb-equals-full-generation-time]
---

对 Kimi（Moonshot）端点的传输层断连（RemoteProtocolError: Server disconnected），**显式传 `thinking.budget_tokens` 没有任何缓解作用——已实测排除**，不要把它当缓解手段。

硬证据（2026-07-30，graph-lab multi_model_mcp.py 调试）：拿同一个"证明题"级复杂 prompt 跑对照实验——`thinking.budget_tokens=8000` 断连、`budget_tokens=2000` 断连、不传 thinking 参数的 baseline 用同一 prompt 也断连，两边失败方式完全一样（都是传输层断连，不是 token 上限）。同一端点简单 prompt baseline 则 HTTP 200 正常返回。结论与实验前的判断相反：断连由 prompt 复杂度/生成时长触发，与 thinking 参数无关。

做法：每个候选缓解手段单独跑对照实验证伪/证实，一次只改一个变量；不要凭"减少推理量→缩短耗时→避开断连"的推理链直接采信。目前唯一验证有效的缓解是重试（不保证每次都成功）。

边界：本实验 unset 了 ALL_PROXY 但 HTTP_PROXY 仍在，不能据此排除代理因素；与 [[llm-api-proxy-timeout-wall-retry-futile]] 互补——那条讲代理超时墙，这条讲 thinking 参数无效。
