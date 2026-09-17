---
id: pi-overwrites-global-dispatcher-after-extension-load
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, extension, undici, dispatcher, connection-reuse]
triggers:
  - "pi 扩展里 setGlobalDispatcher 不生效 / 被覆盖"
  - "想改 pi 的全局 undici dispatcher（keepAlive / 连接复用）"
  - "扩展加载之后 configureHttpDispatcher 又跑了一次"
  - "从 pi bundle 里的 undici 再 set dispatcher 是否生效"
  - "用 diagnostics_channel 数 undici:client:connected 验证连接复用"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-13-15-33-051-lgg4
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: []
---

# pi 扩展里 setGlobalDispatcher 会被 pi 在扩展加载后覆盖，必须推迟到 session_start 幂等安装

## 主张

pi 0.85.1 扩展里 setGlobalDispatcher 会被 pi 自己在扩展加载之后的第二次 `configureHttpDispatcher(settingsManager.getHttpIdleTimeoutMs())`（`dist/main.js:686`）覆盖；要改全局 undici dispatcher 必须推迟到 session_start / before_agent_start 里幂等安装。

## 为什么 / 证据

pi 把 undici 打进 bundle，但 `Symbol.for('undici.globalDispatcher.2')` 跨副本共享，从 pi 的 node_modules `createRequire('undici')` 再 set 是生效的（diagnostics_channel `undici:client:connected` 计数验证：2 回合 2 连接 → 1 连接）。
