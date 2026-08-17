---
id: node-http-host-header-skews-tls-sni
type: bullet
status: deprecated
scope: global
domain: networking
tags: [nodejs, tls, sni, host-header, reverse-proxy]
triggers:
  - "Node 报 Client network socket disconnected before secure TLS connection was established"
  - "http(s).request 显式设置 Host 头后经反代/CDN 断连"
  - "经 tailscale funnel 等按 SNI 路由的链路发 HTTPS 请求"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:capture-2026-08-11-07-57-51-546-itdi
last_verified: 2026-08-12
superseded_by: skill:node-cli-runtime-pitfalls
schema_version: 1
related: [tailscale-serve-preserves-host-header]
---
Node.js 的 http(s).request 显式设置 Host 头会带偏 TLS SNI（servername 取 Host 头值），经按 SNI 路由的反代/CDN 会被直接断连。

**为什么**：Host 头与连接目标域名不一致时，TLS 握手阶段 SNI 即错，链路（如 tailscale funnel）直接断连，报 `Client network socket disconnected before secure TLS connection was established`——错误发生在 TLS 建立前，看不到任何 HTTP 层信息。
**修法**：显式传 `servername`，或让 Host 头与目标域名一致。
**边界**：该报错不是对端服务挂掉，先核对自己发出的 SNI/Host 组合。
**证据**：2026-08-11 经 tailscale funnel 链路调试 Node 客户端时复现并修复。
