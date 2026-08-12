---
id: kimi-coding-endpoint-anthropic-protocol-only
type: lesson
status: candidate
scope: global
domain: llm-ops
tags:
- kimi
- api-endpoint
- anthropic-protocol
- openai-compatible
- provider-integration
triggers:
- 把 Kimi 编码套餐接入 OpenAI 兼容客户端，报 404 resource_not_found
- api.kimi.com/coding 端点 /chat/completions 不通
- 新接 LLM provider 不确定走哪条 wire protocol
- 同一把 key 在一个客户端能用另一个不能（失败信号：协议不匹配）
created: 2026-07-30
evidence:
  helpful: 0
  harmful: 0
verified_by: none
source: session:96b324ab
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: []
---

# Kimi 编码套餐端点只讲 Anthropic 协议：OpenAI 兼容路径 404

**主张**：`https://api.kimi.com/coding` 端点**只实现 Anthropic Messages 协议**（`/v1/messages`，x-api-key 鉴权）；OpenAI 兼容的 `/chat/completions` 返回 HTTP 404 `resource_not_found_error`。接 Kimi 到任意客户端/网关前，先实测两条协议路径，不要默认"是 OpenAI 兼容"。

**证据（实测）**：同一把 `MOONSHOT_API_KEY`：`POST /chat/completions` → 404；`POST /v1/messages` → 200 正常返回（含 thinking block）。pal-mcp-server 因此需要单独的 Anthropic 协议 provider 而不是复用 Custom/OpenAICompatible。

**边界**：编码套餐 key 只在该端点有效（与普通 Moonshot API 不通用）；响应里 thinking block 需要单独解析，只取 `type=="text"` 会丢思维链但不影响正文。

**证据**：session 96b324ab，两协议对照实测记录。
