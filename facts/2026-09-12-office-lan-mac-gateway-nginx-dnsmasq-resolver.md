---
id: office-lan-mac-gateway-nginx-dnsmasq-resolver
type: fact
status: validated
scope: global
domain: macos-networking
tags: [nginx, dnsmasq, etc-resolver, lan-bridge, tailscale, funnel, httpProxy]
triggers:
  - "办公网内 Mac 访问 nanoradar 网关想走内网 IP 而不是 Funnel"
  - "dnsmasq 用 local=/域名/ + address= 把 Funnel 域名答成内网 IP，local= 不能省"
  - "macOS /etc/resolver 多个 nameserver 的回落行为：跨 search_order 文件不回落，同文件才回落"
  - "pi 配了 httpProxy 后 sing-box 远端解析绕回 Funnel"
  - "拔线/插回后网关切换耗时（拔线立即回落 Funnel，插回约 221s 切回内网）"
created: 2026-09-12
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-12-02-31-51-360-32hg
last_verified: 2026-09-12
superseded_by: null
schema_version: 1
related: []
---

# 主张

办公网内 Mac→网关最终方案（2026-09-12）：

- nanoradar（办公 LAN 网关机，192.168.43.x）nginx 加 lanbridge 站点 `listen <LAN-IP>:443 ssl`（tailscale cert 导出到 `/etc/nginx/certs`，cron 每周一续期 + reload）；
- dnsmasq-tslan 服务（dnsmasq-base 二进制 + 自定义 unit）在 LAN IP:53 用 `local=/域名/` + `address=` 把 Funnel 域名答成内网 IP（`local=` 必需，否则 AAAA 转发上游泄漏 Funnel v6）；
- Mac `/etc/resolver/ts.net` 三个 nameserver 按序（内网、119、114）+ `options timeout:1 attempts:1`。

# 证据

实测：

- 两个 search_order 解析器文件之间超时不回落（60s 无结果），同文件多 nameserver 才回落；
- 拔线立即回落 Funnel，插回约 221s 切回内网；
- pi 必须去掉 `httpProxy`（sing-box 远端解析会绕回 Funnel）；
- `/v1/models` 10ms vs Funnel 1.1–4.8s。
