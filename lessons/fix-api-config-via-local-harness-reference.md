---
id: fix-api-config-via-local-harness-reference
type: lesson
status: candidate
scope: global
domain: api-design
tags: [api-config, endpoint, curl, harness, debugging]
triggers:
  - "第三方模型 API 配置打不通，要定位是端点错、协议错还是 key 错"
  - "凭记忆/文档写 baseUrl 和 API 协议，结果 401/404"
  - "本机另一个 harness（pi/Claude Code）里同一个 provider 是能用的"
  - "改代码试错之前想先分钟级验证端点+鉴权"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:0fe7c2be-cdd2-41a5-be17-e2cd31fe1740
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [untested-tool-config-bugs-stay-invisible, verify-external-references]
---

**主张**：修第三方模型 API 配置时，最快的参照物是**本机其他 harness 里已验证可用的同 provider 配置**（如 pi 的 `~/.pi/agent/models-store.json`，含 baseUrl + api 协议字段）；拿到后先 `curl` 裸打端点验证鉴权与协议，再动代码。

**证据**：会话中 `grep "kimi.com/coding" ~/.pi/agent/models-store.json` 拿到 `baseUrl: https://api.kimi.com/coding` + `api: anthropic-messages`；curl 裸打旧配置端点（api.moonshot...）→ `401 Invalid Authentication`，打参照端点 → 返回正常 anthropic message JSON。据此一次改对 `multi_model_mcp.py` 的 kimi 配置，端到端测试通过。整个定位没靠猜文档。

**边界**：参照配置仅证明"该端点+协议组合当时可用"，key 仍需各自有效；harness 配置可能过期，curl 验证这一步不可省。
