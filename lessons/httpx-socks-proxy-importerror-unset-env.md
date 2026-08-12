---
id: httpx-socks-proxy-importerror-unset-env
type: lesson
status: candidate
scope: global
domain: python-http
tags: [httpx, socks, proxy, importerror, env-var]
triggers:
  - "python 脚本调 API 报 ImportError: Using SOCKS proxy, but the 'socksio' package is not installed"
  - "本机环境变量里有 ALL_PROXY=socks5://127.0.0.1:7897 之类的 SOCKS 代理"
  - "一次性脚本/测试脚本要临时绕过代理直连 API"
  - "httpx 请求还没发出去就在客户端初始化阶段抛 ImportError（失败信号）"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:06d00000-c5a0-4247-9e4a-de361d19d25e
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [local-proxy-env-blocks-api-client, long-running-process-needs-restart-after-pip-install]
---

httpx 见到 `ALL_PROXY=socks5://...` 环境变量会尝试走 SOCKS，缺 `socksio` 时在**发请求前**直接抛 `ImportError("Using SOCKS proxy, but the 'socksio' package is not installed")`——这不是网络问题。一次性脚本的最快解法是在 shell 里 `unset ALL_PROXY all_proxy` 再跑，不必装依赖。

硬证据（2026-07-30）：`env | grep -i proxy` 显示 `ALL_PROXY=socks5://127.0.0.1:7897`；测试脚本首跑抛上述 ImportError；同一脚本加 `unset ALL_PROXY all_proxy` 后 ImportError 消失，请求正常发出（后续失败换成了真正的传输层 RemoteProtocolError，是另一回事）。

边界：常驻进程/MCP server 不适用 unset——子进程继承的是启动时的环境，见 [[long-running-process-needs-restart-after-pip-install]]；更广的"代理导致客户端不通"排查见 [[local-proxy-env-blocks-api-client]]。若确实需要走 SOCKS，则正解是 `pip install socksio`。
