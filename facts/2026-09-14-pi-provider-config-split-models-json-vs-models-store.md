---
id: pi-provider-config-split-models-json-vs-models-store
type: fact
status: validated
scope: global
domain: pi-harness
tags: [pi, provider, config-layout, models-store, auth-json]
triggers:
  - "排查 pi 连不通：端点与模型清单看哪个文件"
  - "pi 的 models-store.json 存什么，删掉会不会丢 provider"
  - "~/.pi/agent/models.json 与 models-store.json 的职责区分"
  - "pi --list-models 正常，想确认 provider 配置没丢"
  - "pi auth check --provider 该查哪个文件"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-07-17-31-306-8cob
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: []
---

# pi 的 provider 配置与目录缓存已分离

## 主张

pi 的 provider 配置与目录缓存已分离，旧条目 pi-credentials-auth-json-models-store 的布局描述（models-store.json 存 provider 的 baseUrl/api/模型清单）已过时，应置其 superseded_by 指向本条。

## 证据（2026-09-14 实测）

①用户 provider 配置（baseUrl/api/apiKey/models）在 `~/.pi/agent/models.json`；②models-store.json 已变成「远端模型目录缓存」——由 `dist/core/models-store.js` 的 FileModelsStore 持有，配合 withRemoteCatalog 从 `https://pi.dev/api/models/providers/<id>` 拉取，每条含 `{models, checkedAt, lastModified, etag}`，4h 复验周期；删掉该文件后 pi 立即重建为 `{}`，且 `pi --list-models` 与 `pi auth check --provider deepseek-internal` 均正常 → 证明它不承载用户配置、可安全重建，删它不会丢 provider。③auth.json 仍是凭据位置（本机为 `{}`）。

## 排查顺序

排查 pi 连不通时的查证顺序：端点与模型清单看 models.json，凭据看 auth.json，models-store.json 只是缓存、不必看。
