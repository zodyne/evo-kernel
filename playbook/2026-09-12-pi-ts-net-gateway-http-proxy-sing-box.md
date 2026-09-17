---
id: pi-ts-net-gateway-http-proxy-sing-box
type: lesson
status: validated
scope: global
domain: macos-networking
tags: [pi, tailscale, funnel, httpProxy, sing-box, packet-loss, connect-timeout]
triggers:
  - "pi 走 ts.net 网关报 'Request timed out.'，10s 建连超时"
  - "联通直连东京 Funnel 入口丢包 10–15%，想给 pi 配 httpProxy"
  - "~/.pi/agent/settings.json 的 httpProxy 该怎么设"
  - "验证 pi 代理是否生效：env -u 掉 shell 代理变量 + 看 sing-box 日志 inbound 行"
  - "Tailscale DERP map 无大陆节点 / Funnel 入口不能选区域"
created: 2026-09-12
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-12-00-01-37-048-w5x8
last_verified: 2026-09-12
superseded_by: null
schema_version: 1
related: []
---

# 主张

pi 的 ts.net 网关走联通直连到东京 Funnel 入口丢包 10–15%，10s 建连超时 → `Request timed out.`；改 `~/.pi/agent/settings.json` 的 `httpProxy` 指向本机回环上 sing-box 的混合代理端口（localhost:1080，即 `httpProxy=http://<localhost>:1080`）后 10/10。

# 为什么 (证据)

- 直连：丢包 10–15%，10s 建连超时 → `Request timed out.`
- 配 `httpProxy` 后：10/10。
- 验证方法：用 `pi -p` 并 `env -u` 掉 shell 代理变量，看 sing-box 日志新增 inbound 行。
- Tailscale DERP map 无大陆节点，Funnel 入口不可选区域。
