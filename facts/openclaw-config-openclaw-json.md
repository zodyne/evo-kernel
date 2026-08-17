---
id: openclaw-config-openclaw-json
type: fact
status: archived
scope: global
domain: harness-config
tags: [openclaw, api-key, provider, config]
triggers:
  - "找 openclaw 的 API key / token / 端点配置"
  - "要确认 openclaw 的 provider profile 或网关地址"
  - "openclaw 里 NOVASKY_API_KEY / GITLAB_TOKEN 等密钥存在哪"
  - "收集本机各 agent/harness 的凭据与接入点信息"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fadd9-8a08-71ac-a7ec-763d06fbfb08
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [pi-credentials-auth-json-models-store, fix-api-config-via-local-harness-reference]
---

**主张**：openclaw 的本机配置集中在 `~/.openclaw/openclaw.json`，单个 JSON 内含 `auth.profiles`（如 `zai:default` 指定 provider）和 `env.vars`（NOVASKY_API_KEY、GITLAB_TOKEN、NO_PROXY 等密钥与环境变量）。

**证据**：会话中 `ls -la ~/.openclaw` 确认目录存在；python 读 `openclaw.json` 输出 `.auth.profiles.zai:default.provider = zai` 及 `.env.vars.NOVASKY_API_KEY = sk-...`、`.env.vars.GITLAB_TOKEN = glpat-...`（均打码）、`NO_PROXY` 列表（含内网网关域名）。

**边界**：该文件同时含密钥与端点，读取时必须打码（见 `mask-secrets-when-reading-config`）；目录权限为 `drwx------`（700），属单机个人配置，不在任何 git 仓库内。
