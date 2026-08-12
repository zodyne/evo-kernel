---
id: llm-api-proxy-timeout-wall-retry-futile
type: lesson
status: candidate
scope: global
domain: llm-api
tags: [httpx, proxy, timeout, retry]
triggers:
  - "httpx 报 RemoteProtocolError: Server disconnected without sending a response"
  - "LLM API 非流式长请求在 130~170 秒左右固定被掐断（失败信号）"
  - "给 API 调用加重试逻辑，重试后仍然在相近耗时失败"
  - "本机开着代理（Clash 等），curl 短请求能通但长生成请求断"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:583c96aa-69cd-41b3-926b-4f72d4d7c7f5
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [nonstream-ttfb-equals-full-generation-time, local-proxy-env-blocks-api-client]
---

要区分两类 API 失败：**瞬时错误**（连接失败/5xx/429，重试有效）和**确定性超时墙**（重试也撞同一堵墙）。

会话证据：经代理请求 Kimi（Anthropic 兼容端点）长生成，两次分别在 elapsed=173.5s 和 134.6s 抛 `RemoteProtocolError: Server disconnected without sending a response`——耗时量级一致，是中间链路（代理）的固定超时墙，不是随机抖动。短请求同端点 status=200 正常。

对策：重试只包瞬时错误；对确定性墙要换路——改流式（让中间链路持续有字节）、缩短 prompt/max_tokens、或绕开代理直连。给重试逻辑注释如实标注"非根治"。
