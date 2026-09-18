---
id: singbox-dns-server-domain-address-needs-resolver
type: lesson
status: candidate
scope: global
domain: network
tags: [sing-box, dns, domain-resolver, config-fatal, tun, macos]
triggers:
  - "sing-box 配置里 dns.servers 的 server 字段写成域名（如 dns.google）而不是 IP 地址"
  - "sing-box 启动/加载配置时报 FATAL initialize DNS server[0]: missing domain resolver for domain server（失败信号）"
  - "要把 sing-box 的 DNS 上游指向 DoH/DoT 域名，却卡在配置起不来"
  - "从别处抄来的 sing-box DNS 段只换成了新格式，地址仍是域名，在本机复现失败"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-5266-73b1-bdd8-c2d0c6a8eec4
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [singbox-legacy-dns-servers-deprecated-1-12, singbox-config-doc-validate-with-real-check]
---

# sing-box 的 dns.servers 条目地址写域名会 FACTAL 起不来：缺 domain resolver

**一句话主张**：sing-box（本机实测 1.13.19）里 `dns.servers[i]` 的 `server` 写成**域名**（如 `dns.google`）时，
配置在 DNS 初始化阶段直接失败：`FATAL[0000] initialize DNS server[0]: missing domain resolver for domain server`；
把该 server 写成 **IP**（新格式 `{"type":"udp","tag":"local-dns","server":"223.5.5.5"}`）配置就能起（实测 rc=0）。
要用域名就必须额外给一个 domain resolver，只换 DNS 段格式、不动地址是不够的。

**为什么**：DNS server 条目本身要用域名时，这个域名得先被解析，而解析它又得先有可用的 DNS —— 自举依赖；
所以 sing-box 要求显式指定「用哪个解析器解析这个域名」（`domain_resolver` 一档），缺了就在初始化阶段报
`missing domain resolver for domain server`。注意域名写在 **outbound** 的 server 上不会报这个错（实测 `rc=0`），
这一档只针对 DNS server 条目。

**证据**（会话 01a0b2ce 的变体矩阵，命令↔结果）：
- `cd /tmp && printf '%s' '{"dns":{"servers":[{"type":"udp","tag":"local-dns","server":"dns.google"}]},"outbounds":[...socks...]' …`
  → `== D: dns server=hostname + rule ==` `FATAL[0000] initialize DNS server[0]: missing domain resolver for domain server`
- 同批变体里 DNS server 用 IP 的新格式配置 → `rc=0`；`== A: domain outbound, no resolver == rc=0`（域名在 outbound 上不报）。
- 变体矩阵里另有一组 `== B: + default_domain_resolver == rc=0`，但该组 DNS server 用的是 IP，
  **未**单独验证「补 default_domain_resolver 能否救回域名 server」——本条不宣称已验过该修法能消除 D 的 FATAL。

**边界**：本条只钉「DNS server 条目地址写域名 → 初始化 FATAL」这一档，以及「地址换 IP → 通过」这个已验证出路；
domain resolver 的字段名/放置层级（写在 dns 级还是 route 级）本次证据未区分，别照抄结论。
与 `singbox-legacy-dns-servers-deprecated-1-12`（旧 `address` 字符串格式被弃用）是同一段配置上的两个独立坑：
先过格式关，再撞这条 domain resolver 关。
