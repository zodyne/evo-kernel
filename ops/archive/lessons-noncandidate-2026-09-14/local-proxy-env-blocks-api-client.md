---
id: local-proxy-env-blocks-api-client
type: lesson
status: deprecated
scope: global
domain: networking
tags: [proxy, env, httpx, api-debugging]
triggers:
  - "脚本里调 LLM/HTTP API 报连接错误，traceback 里看不到 HTTP 请求日志"
  - "本机开着 Clash 类代理（ALL_PROXY=socks5://127.0.0.1:7897 等）"
  - "curl 能通但 python/node 客户端不通，或反之"
  - "排查 API 不通，第一步不知道该查什么"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:0fe7c2be-cdd2-41a5-be17-e2cd31fe1740
last_verified: 2026-07-29
superseded_by: skill:network-reachability-diagnosis
schema_version: 1
related: []
---

**主张**：本机代理环境变量（`ALL_PROXY`/`HTTP_PROXY`/`HTTPS_PROXY`，如 socks5://127.0.0.1:7897）会让脚本里的 API 客户端请求在发出前就失败；排查 API 不通先 `env \| grep -i proxy`，用 `env -u ALL_PROXY -u all_proxy -u HTTP_PROXY -u http_proxy -u HTTPS_PROXY -u https_proxy` 前缀剥离后再试。

**证据**：会话中调智谱 API 连续 exit 1，traceback 里没有任何 HTTP 请求日志；`env \| grep -i proxy` 显示 5 个代理变量指向本机 socks5/http 代理；加 `env -u ...` 前缀后日志里首次出现 `HTTP Request: POST https://open...`，后续调用成功。

**边界**：代理是必要出口的网络环境下此法不适用；判别信号是"剥离代理前后，请求日志是否从无到有"。
