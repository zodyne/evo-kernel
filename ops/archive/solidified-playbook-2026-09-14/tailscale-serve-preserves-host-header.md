---
id: tailscale-serve-preserves-host-header
type: bullet
status: deprecated
scope: global
domain: networking
tags: [tailscale, nginx, reverse-proxy, host-header, sse]
triggers:
  - "tailscale serve/funnel 反代后上游返回 404"
  - "new-api/one-api 网关经 tailscale serve 访问 404"
  - "上游 nginx 按 Host 头路由（只认自己域名）"
  - "反代链路里 SSE 流式响应被缓冲"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:capture-2026-08-11-07-13-39-253-e3zy
last_verified: 2026-08-12
superseded_by: skill:network-reachability-diagnosis
schema_version: 1
related: [node-http-host-header-skews-tls-sni, tailscale-funnel-manual-enable-dns-delay]
---
tailscale serve/funnel 反代保留原始 Host 头（Go httputil.ReverseProxy 默认行为），上游若按 Host 路由会被 404。

**为什么**：上游 nginx 若按 Host 路由（如 new-api/one-api 网关只认自己域名），经 serve 的请求带的是 tailnet 域名的 Host 头，匹配不到任何 server block 即 404。
**修法**：桥梁机本地加一层 nginx 反代：`listen 127.0.0.1:18080`，`proxy_set_header Host <上游域名>`，`proxy_buffering off`（支持 SSE 流式），serve 改指 `http://127.0.0.1:18080`。
**边界**：这是 Go httputil.ReverseProxy 的默认行为，不是 tailscale 配置错误；不能指望 serve 自身改写 Host。
**证据**：2026-08-11 本机架设 new-api 网关经 tailscale 暴露时复现并按上法修复。
