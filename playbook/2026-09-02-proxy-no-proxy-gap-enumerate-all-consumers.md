---
id: proxy-no-proxy-gap-enumerate-all-consumers
type: lesson
status: validated
scope: global
domain: networking
tags: [proxy, no_proxy, NO_PROXY, 消费者枚举, 502, claude-code]
triggers:
  - proxy-on 只设 http_proxy/https_proxy/all_proxy 不设 no_proxy
  - 同一个 no_proxy 缺口在又一个独立消费者上被踩中
  - 消费端加固只修了一个消费者（失败信号：没枚举全部消费者清单）
  - Claude Code 的 gbrain MCP HTTP 客户端 502
  - 想全局给 proxy-on 补 no_proxy 但触碰 VPN 配置红线
created: 2026-09-02
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-02-01-35-35-655-e7vp
last_verified: 2026-09-02
superseded_by: null
schema_version: 1
related: [searxng-all-engines-fail-check-outgoing-proxy, httpx-socks-proxy-importerror-unset-env]
---

# 同一个 no_proxy 缺口在第三个独立消费者上被踩中：消费端加固要枚举全部消费者

同一个 no_proxy 缺口（proxy-on 只设 http_proxy/https_proxy/all_proxy 不设 no_proxy）在第三个独立消费者上被踩中：09-01 只加固了 gbrain-maintenance.sh 和 hermes-watchdog.py 的健康检查 curl，没覆盖 Claude Code 自己的 gbrain MCP HTTP 客户端，导致 502。

## 教训

消费端加固要枚举全部消费者清单，不能修一个算一个；更彻底的修法（全局 proxy-on 补 no_proxy）因触碰 VPN 配置红线被搁置，代价是每个新消费者都要单独踩坑才会被发现。

## 本次修法

本次对 Claude Code 侧的修法是 ~/.claude/settings.json 加 env.NO_PROXY，不碰 proxy-on()。
