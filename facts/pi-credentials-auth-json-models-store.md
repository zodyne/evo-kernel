---
id: pi-credentials-auth-json-models-store
type: fact
status: candidate
scope: global
domain: harness-config
tags: [pi, api-key, provider, config]
triggers:
  - "找 pi（pi-coding-agent）的 API key 或 provider 凭据"
  - "要确认 pi 某个 provider 实际生效的 baseUrl / API 协议"
  - "跨 harness 对齐同一个 provider 的接入配置（端点/协议/模型名）"
  - "排查 pi 模型连不通，想看本机配置的端点和模型清单"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fadd9-8a08-71ac-a7ec-763d06fbfb08
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [pi-mcp-adapter-global-config-path, fix-api-config-via-local-harness-reference]
---

**主张**：pi（pi-coding-agent）的 provider API key 在 `~/.pi/agent/auth.json`（按 provider 分 `type`/`key`）；provider 的 baseUrl、API 协议、模型清单在 `~/.pi/agent/models-store.json`（顶层按 provider 分组）。收集/核对 pi 的接入信息看这两个文件即可，不用翻 npm 包源码。

**证据**：会话中 `ls ~/.pi/agent/` 确认两文件存在；`cat models-store.json` 显示 `zai-coding-cn` 的 `baseUrl=https://open.bigmodel.cn/api/coding/paas/v4`、`api=openai-completions`、模型含 glm-4.5-air / glm-4.7；python 读 `auth.json` 显示 `kimi-coding`、`zai-coding-cn` 各含 `type = api_key` + key（输出打码）。

**边界**：密钥只在 `auth.json`，`models-store.json` 不含密钥（可直接 cat）；读 `auth.json` 必须打码（见 `mask-secrets-when-reading-config`）。两文件均为本机运行时状态，结构以 provider 名为顶层 key，字段名以实际文件为准。
