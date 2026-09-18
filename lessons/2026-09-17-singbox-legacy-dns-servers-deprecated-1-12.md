---
id: singbox-legacy-dns-servers-deprecated-1-12
type: lesson
status: candidate
scope: global
domain: network
tags: [sing-box, dns, config-migration, deprecated, tun]
triggers:
  - "写/改 sing-box TUN 入站配置，配了旧版 dns.servers（address 字符串形式）"
  - "sing-box check 报 legacy DNS servers is deprecated in 1.12.0 and will be removed（失败信号）"
  - "把 macOS 上能跑的 sing-box 配置迁到新版/其他平台，DNS 段照抄报错"
  - "迁移 sing-box 配置到 1.12+，不知道 DNS 服务器段的新写法"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0affb-58dd-73b1-bdd8-c2ca9d44ed64
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [singbox-1-12-route-needs-default-domain-resolver, pi-ts-net-gateway-http-proxy-sing-box]
---

sing-box 1.12.0 起 `dns.servers` 旧格式（`"address": "<dns>"` 字符串形式）被弃用，`sing-box check` 直接报错 `legacy DNS servers is deprecated in sing-box 1.12.0 and will be removed`，写 TUN 配置必须用新格式（`"type": "udp"` + `server` 字段的对象形式）。

为什么：为 Windows 机器准备 sing-box TUN 部署配置时，DNS 段照搬了能跑的旧写法，check 当场拒绝；改写成新版对象格式（`{"type":"udp","tag":"local-dns","server":"<dns>"}`）后 check 通过。

边界：本条只覆盖 DNS servers 段本身的格式迁移；修完这一处还会接着报缺 `route.default_domain_resolver`（见 related 条目），两处都要改才能 PASS。基于 sing-box 1.13.19 实测。

证据：会话内 `sing-box check` 实测——旧格式变体输出 `ERROR[0000] legacy DNS servers is deprecated in sing-box 1.12.0 and will be removed`，改新版格式 + 补 default_domain_resolver 后输出 `✅ PASS`。
