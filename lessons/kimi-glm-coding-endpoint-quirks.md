---
id: kimi-glm-coding-endpoint-quirks
type: lesson
status: candidate
scope: global
domain: llm-tooling
tags: [kimi, glm, coding-plan, api-protocol, retry, mcp]
triggers:
  - "接 kimi/glm 第三方模型到 MCP 或多模型工具"
  - "编码套餐 key 在标准计费端点报 401/429（失败信号）"
  - "kimi 长 prompt 调用在 2-3 分钟处连接被掐断（RemoteProtocolError）"
  - "外部模型工具从未被真实调用验证过"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:0fe7c2be（合并 session:0a908942）
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
---
# 编码套餐 key 只在套餐端点有效，且 kimi 端点讲 Anthropic 协议、GLM 讲 OpenAI 协议

**主张**：智谱 `ZHIPU_API_KEY` / Moonshot `MOONSHOT_API_KEY` 的"编码套餐" key 不是标准计费 key，只在各自套餐端点有效；两家端点协议不同——GLM 编码端点是 OpenAI `/chat/completions` 格式，kimi 编码端点是 **Anthropic Messages `/v1/messages`** 格式。多模型注册表必须带 `api: "openai"/"anthropic"` 字段分流请求构造与响应解析（`tool_calls` vs `tool_use`）。

**为什么**：协议写错时调用静默打不通，且"工具从未被真实调用测试过"会让这种 bug 长期潜伏——`ask_external_model`/`poll_models` 对 kimi 一直是死的（错误端点+错误协议），直到做 agentic 工具调用时才暴露。另外 kimi-k3 对复杂/长 prompt 会在约 130–175s 处被链路掐断（`httpx.RemoteProtocolError: Server disconnected`），与 max_tokens 无关，重试（429/5xx + TransportError，退避 3s/8s）是目前唯一验证有效的缓解。

**边界**：端点与协议对应关系是 2026-07 实测快照，供应商可能调整；本地 Ollama 等 provider 不在此列。重试只是缓解不保证避开掐断。

**证据**：session 0fe7c2be 修复 `graph-lab/tools/multi_model_mcp.py` 后 GLM（read_file→bash→write_file）与 Kimi（bash）真实端到端验证通过；session 0a908942 实测 130–175s 掐断并加 `_post_with_retry`。
