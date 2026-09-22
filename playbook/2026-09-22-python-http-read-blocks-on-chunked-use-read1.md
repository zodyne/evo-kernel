---
id: python-http-read-blocks-on-chunked-use-read1
type: playbook
status: validated
scope: global
domain: python
tags: [python, http-client, sse, streaming, proxy, chunked]
triggers:
  - "写 Python 流式转发代理，客户端的 SSE 心跳被攒住、直到流结束才一次性送达"
  - "代理后的请求在上游思考停顿期被客户端看门狗掐断（长时间零字节）"
  - "http.client 的 read(n) 在 chunked 响应上行为不符合流式预期"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:inbox/capture-2026-09-19-04-56-38-921-yx9u
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [streaming-protocol-snapshot-vs-delta, claude-code-nanoradar-gateway-settings]
---

# Python `HTTPResponse.read(n)` 在 chunked 响应上会攒够 n 字节才返回：SSE 代理必须用 `read1(n)`

**主张**：`http.client.HTTPResponse.read(n)` 在 chunked 响应上**阻塞到攒够 n 字节或流结束**才返回，
不是「有几个字节返回几个」。**SSE** 转发代理要逐块透传就必须改用 `resp.read1(n)`。

## 证据（一次回环观测）

- 6 个 36B 的 SSE ping、每 0.3s 一个：`read(4096)` 到 t=1.82s 流结束才一次性返回 216B；
  `read1(4096)` 则逐个 0.3s 返回。
- 代价（同一次记录）：Claude Code 的 BASE_URL 字节级看门狗（300s 无字节掐流）会在纯 ping 的
  思考停顿期被触发。见 `~/claude-code-mix/mix_proxy.py:219`。

**为什么** `read(n)` 会攒批（是否内部循环调用底层、`read1` 的确切语义）**本次没有测**——
本条只记「实测表现成什么样」，不解释机制。

证据等级：`verified_by: human` —— 来源是会话内的 prose 摘要（`capture:…`），无命令转录（样本量 1）。
**未经本机复核** —— `command` 档要求命令级可复现证据，本条没有。

## 边界 / 反例

- 观测对象是 **chunked 响应**。`Content-Length` 已知的响应本次**没测**——不要替它下结论。
- 结论只到 **SSE 转发代理**为止。其它形态的代理（如非流式、一次性收全再转发）本次没有观测，
  本条不对它们作断言。
