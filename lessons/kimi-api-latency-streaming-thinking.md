---
id: kimi-api-latency-streaming-thinking
type: lesson
status: deprecated
scope: global
domain: llm-api
tags: [kimi, api-latency, streaming, thinking, watchdog]
triggers:
  - "kimi API 调用超时/看门狗误杀"
  - "大输入 prompt 首字节几十秒"
  - "子代理评审任务 600s 不够"
  - "kimi-k3 max_tokens 设多少"
  - "非流式请求像挂死"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:583c96aa+b6cf7fd7
last_verified: 2026-07-30
superseded_by: skill:hermes-custom-providers
schema_version: 1
---

**主张**：kimi（api.kimi.com/coding，anthropic-messages 契约）在大输入 + 非流式 + thinking 下延迟极高：实测 26KB 输入首字节 90s、吞吐约 20 tok/s 且非流式首字节≈总耗时；改流式后同输入首字节 7.2s。给这类调用设看门狗要按「输入大小 + thinking 等级 + 输出上限」估到 10–15 分钟量级，否则会把「慢」误判成「挂死」。

**为什么**：pi agent 评审任务连续超时，层层排除提供侧/网络/MCP 后，直连 API 计时才锁定根因是看门狗设短了；kimi-k3 官方 `context_length` 1,048,576 且 thinking 强制开启（`supports_thinking_type: "only"`），`thinking.budget_tokens` 等参数传了返回 200 但无法验证生效。

**边界**：max_tokens 不要拍脑袋——拿同量级真实 prompt 实测消耗再留余量（实测 6316 字符复杂 prompt 约耗 3000 output tokens，4096 会截断，设 16000）；网络瞬时错误可重试（退避 3s/8s，≤2 次），但确定性的 ~150s 代理超时墙重试大概率撞同一堵墙，要如实标注局限而非假装修复。

**证据**：2026-07-29 evo-kernel 会话 pi 协同失败根因分析 + 2026-07-30 ucm221 会话 multi-model MCP 修复，两处独立实测一致。
