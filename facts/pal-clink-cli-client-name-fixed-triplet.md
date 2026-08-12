---
id: pal-clink-cli-client-name-fixed-triplet
type: fact
status: validated
scope: global
domain: pal-mcp
tags: [pal-mcp, clink, cli-client, registry, provider]
triggers:
  - "配置 PAL clink 自定义 CLI client"
  - "想给同一个 CLI 按 provider 并存多份 clink 配置"
  - "clink 调用因 client name 校验失败"
  - "想用 GLM 后端的 claude 子代理"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-07-29-15-18-38-122-3pyg
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [pal-custom-provider-models-json-registry, pal-default-model-env-only-affects-fallback]
---
PAL clink 自定义 CLI client 的 `name` 必须是 claude / gemini / codex 三者之一：`registry.py` 用 `INTERNAL_DEFAULTS.get(name)` 硬校验，其他名字直接拒绝。

**推论**：同一 CLI 只能存在一份配置——想按 provider 并存多个 claude client（如官方 Anthropic 一份、GLM 后端一份）做不到。要用 GLM 后端的 claude 子代理，只能在 `~/.pal/cli_clients/claude.json` 里整体覆盖 env。

**边界**：这是 PAL registry 的硬编码约束，不是配置写法问题；改 name 绕不开，只能改 PAL 源码或接受单配置覆盖。
