---
id: ts-net-funnel-alidns-nxdomain-resolver-split
type: lesson
status: validated
scope: global
domain: macos-networking
tags: [dns, alidns, nxdomain, mdnsresponder, etc-resolver, tailscale, funnel, openai-node]
triggers:
  - "pi/hermes 对 nanoradar.tail7a2064.ts.net 间歇报 'Connection error.'"
  - "Mac 上手动配置的 AliDNS（阿里公共 DNS）对 ts.net Funnel 域名返回 NXDOMAIN、getaddrinfo ENOTFOUND"
  - "想给某个域名做分域解析而不改默认 DNS（/etc/resolver/<domain>）"
  - "dig 能解析但应用仍失败，验证 DNS 该用 dscacheutil/curl/Node"
  - "openai-node 把 fetch 错误统一映射成 'Request timed out.'/'Connection error.'，找不到真实 cause（失败信号）"
created: 2026-09-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-11-14-01-19-460-jyqt
last_verified: 2026-09-11
superseded_by: null
schema_version: 1
related: []
---

# 主张

pi/hermes 对 `nanoradar.tail7a2064.ts.net` 的 `Connection error.` 抖动，根因是 Mac 手动配置的 AliDNS（阿里公共解析器）对该 Funnel 域名约 50% 返回 NXDOMAIN；macOS mDNSResponder 把否定应答缓存 ≤300s，于是整段时间 `getaddrinfo` 报 ENOTFOUND。

修法：`/etc/resolver/ts.net` 分域解析（nameserver 改用另两家公共 DNS：DNSPod / 114DNS）——全系统生效、不改默认 DNS、不碰 sing-box。

# 证据

- 权威 dnsimple 32/32 正常，DNSPod / 114DNS 为 0/15，AliDNS 约 50% NXDOMAIN。
- 验证口径：curl 走系统 DNS 3 分钟探测，修前 34/36 失败。
- `dig` 不走 `/etc/resolver`，验证必须用 `dscacheutil` / `curl` / Node。

# 附：错误信息掩盖真实 cause

openai-node 把任何 message 含 `timeout` 的 fetch 错误都映射成 `Request timed out.`，其余映射成 `Connection error.`，两者都掩盖真实 cause。
