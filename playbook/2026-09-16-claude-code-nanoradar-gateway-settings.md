---
id: claude-code-nanoradar-gateway-settings
type: lesson
status: validated
scope: global
domain: claude-code
tags: [claude-code, anthropic-api, gateway, apikeyhelper, thinking-budget]
triggers:
  - "让 Claude Code 直连 nanoradar new-api 网关"
  - "ANTHROPIC_BASE_URL 指向 tailscale 网关，走 Anthropic /v1/messages"
  - "thinking budget_tokens 必须 ≥1024 否则 400"
  - "apiKeyHelper 与 claude.ai 登录 / ANTHROPIC_AUTH_TOKEN 的优先级"
  - "haiku 别名没映射到网关模型导致后台调用 404"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-16-13-56-51-376-fux6
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [fix-api-config-via-local-harness-reference]
---

# Claude Code 可直连 nanoradar new-api 网关

## 主张

Claude Code 可直连 nanoradar new-api 网关：`ANTHROPIC_BASE_URL=https://nanoradar.tail7a2064.ts.net`（网关原生支持 Anthropic `/v1/messages`，含 stream/thinking/tool_use，Bearer 与 x-api-key 均可）；thinking budget_tokens 必须 ≥1024 否则 400。

## 配置要点

apiKeyHelper 优先级高于 claude.ai 登录（低于 ANTHROPIC_AUTH_TOKEN/API_KEY），复用 pi 的 awk 读 `~/.hermes/.env` 即可；haiku 别名必须也映射到网关模型否则后台调用 404。

## 证据

实测 `claude -p --settings <文件>` → modelUsage=deepseek-v4-flash。样板：`~/Desktop/claude-settings-deepseek-internal.json`（2026-09-16）。
