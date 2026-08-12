---
id: openclaw-model-override-needs-whitelist
type: bullet
status: validated
scope: global
domain: harness-config
tags:
- openclaw
- provider
- whitelist
- model-override
- config
triggers:
- openclaw 加完 provider 后指定模型报 Model override not allowed
- openclaw agent --model provider/model 被拒，路由明明已配好
- 编辑 ~/.openclaw/openclaw.json 的 agents.defaults.models
- 在 openclaw 里用 provider/model 形式覆盖默认模型
created: 2026-08-07
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: session:capture-2026-08-07-13-41-38-537-9lbi
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: []
---
openclaw 新增 provider 路由后，还必须把 `provider/model` 加进 `agents.defaults.models` 白名单（带 alias），否则报 `Model override not allowed`。

**做法**：编辑 `~/.openclaw/openclaw.json` 的 `models.providers` 加 provider（api 字段支持 `openai-responses`），同步在 `agents.defaults.models` 白名单登记该 `provider/model`；用 `openclaw config validate` + `openclaw agent --local --model X -m ... --session-id t --json` 端到端验证。
**边界**：codex 中转站 https://api.gpteamservices.com 的 `/responses` 与 `/v1/responses` 均可用，key 在 `~/.codex/auth.json`。
**证据**：2026-08-07 本机实操，未加白名单时报 `Model override not allowed`，补登后验证通过。
