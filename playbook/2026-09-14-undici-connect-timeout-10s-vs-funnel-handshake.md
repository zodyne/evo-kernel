---
id: undici-connect-timeout-10s-vs-funnel-handshake
type: lesson
status: validated
scope: global
domain: networking
tags: [undici, timeout, keepalive, funnel, cgnat, tcp]
triggers:
  - "pi 走 Funnel 报 'Request timed out.' 恒定在请求后 ~10.5s"
  - "undici 默认 connect timeout 10s / keepAliveTimeout 4s 导致工具调用后每回合重新握手"
  - "工具调用超过 4s 后空闲 TCP 连接被丢弃"
  - "家里电信宽带 CGNAT 下空闲 TCP 连接被静默丢弃（请求挂 20s 无响应）"
  - "想加 TCP keepalive 探测维持长连接复用"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-13-15-33-086-6c1f
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: []
---

# pi 走 Funnel 时 "Request timed out." ≈ undici 默认 connect timeout 10s；keepAliveTimeout 4s 导致每回合重握手

## 主张

pi 走 Funnel 时 `'Request timed out.'` 恒定在请求后 ~10.5s = undici 默认 connect timeout 10s（TCP+TLS 握手没在 10s 内完成），openai-node 把 cause 里含 `'timeout'` 的 fetch 失败归为 APIConnectionTimeoutError；undici 默认 keepAliveTimeout 4s → 工具调用 >4s 后每回合重新握手。

## 证据

家里电信宽带（CGNAT 100.64/10）空闲 TCP 连接 90s 可复用、120s 静默丢弃（请求挂 20s 无响应），加 TCP keepalive 25–30s 探测后 120s/240s 空闲仍复用。
