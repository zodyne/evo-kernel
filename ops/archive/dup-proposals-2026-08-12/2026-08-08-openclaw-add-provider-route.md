---
id: openclaw-add-provider-route
type: lesson
status: candidate
scope: global
domain: harness-config
tags: [openclaw, provider, api-route, openai-responses, config]
triggers:
  - "给 openclaw 增加一个新的模型 provider（中转站 / OpenAI 兼容端点）"
  - "编辑 ~/.openclaw/openclaw.json 的 models.providers 加 provider 路由"
  - "openclaw agent 实测报 Error: Pass --to <E.164>, --session-（失败信号：缺 --session-id）"
  - "新加的 provider 在 openclaw 里识别不到或调不通，想验证路由是否生效"
  - "openclaw provider 的 api 字段该填 openai-responses 还是 openai-completions"
created: 2026-08-08
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fdc53-9fe9-7b95-b8e5-5e685b880cdc
last_verified: 2026-08-08
superseded_by: null
schema_version: 1
related: [openclaw-config-openclaw-json, fix-api-config-via-local-harness-reference]
---

**主张**：往 openclaw 增加 OpenAI 兼容中转站 provider 路由 = 编辑 `~/.openclaw/openclaw.json` 的 `models.providers` 下新增 provider 对象（设 `baseUrl`、`api` wire 协议字段如 `openai-responses`/`openai-completions`、`models` 列表），先 `openclaw config validate` 过，再用 `openclaw agent --local --model <provider>/<model> -m "..." --session-id <id> --json` 闭环实测——**`--session-id` 必填**，缺则报 `Error: Pass --to <E.164>, --session-...`。

**证据**：会话中 python 读 `openclaw.json` 的 `models` 见 `mode: "replace"`、`providers.novasky` 含 `baseUrl` + `api: "openai-completions"`；在 `models.providers` 下新增 `gpteams`（baseUrl 指向中转站）后 `openclaw config validate` → `Config valid`；首次 `openclaw agent --local --model gpteams/gpt-5.6-sol -m "..." --json`（无 `--session-id`）→ `Error: Pass --to <E.164>, --session-`；补 `--session-id test-gpteams` 后 → `{"payloads":[{"text":"pong"}],"meta":{"durationMs":6270}}` 实测通过。中转站 key 与端点取自本机 codex 的 `~/.codex/auth.json`（即 fix-api-config-via-local-harness-reference 的跨 harness 参照法）。

**边界**：
- `models.mode: "replace"` 下 provider 全由配置定义（不合并内置），改完务必 `validate` + 实测，别只看 `openclaw models list`。
- `api` 字段取值须匹配中转站支持的 wire 协议（responses vs completions），可参照 `models.providers` 内已有同协议 provider；本次未单独验证两者差异，中转站一般两者皆支持。
- 动手前先 `cp ~/.openclaw/openclaw.json <bak-时间戳>` 备份（本会话即先备份再改）。
- key 操作须打码：本会话有一处 `print(k)` 把完整 key 明文落进了 transcript，详见 mask-secrets-when-reading-config（主张相同，不另起条目）。
