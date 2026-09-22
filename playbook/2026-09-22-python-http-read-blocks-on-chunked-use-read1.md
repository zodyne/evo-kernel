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
verified_by: command
source: capture:inbox/capture-2026-09-19-04-56-38-921-yx9u
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [streaming-protocol-snapshot-vs-delta, claude-code-nanoradar-gateway-settings]
---

# Python `HTTPResponse.read(n)` 在 chunked 响应上会攒够 n 字节才返回：流式代理必须用 `read1(n)`

**主张**：`http.client.HTTPResponse.read(n)` 在 chunked 响应上**阻塞到攒够 n 字节或流结束**才返回，
不是「有几个字节返回几个」。流式（SSE）转发代理必须改用 `resp.read1(n)` 才能逐块透传。

## 为什么

`read(n)` 的语义是「读满 n 字节」，它内部会循环调用底层；`read1(n)` 才是「最多读 n 字节，有一次
底层数据就返回」。回环实测：6 个 36B 的 SSE ping 每 0.3s 一个，`read(4096)` 到 t=1.82s 流结束才
一次性返回 216B；`read1(4096)` 则逐个 0.3s 返回。

## 证据（本会话实测）

- 回环 pty/stream 实测上述时间线（6×36B / 0.3s 间隔）。
- 现实后果：Claude Code 的 BASE_URL 字节级看门狗（300s 无字节掐流）会在**纯 ping 的思考停顿期**
  被触发 —— 代理看似"没坏"，客户端却周期性断流。见 `~/claude-code-mix/mix_proxy.py:219`。

## 边界 / 反例

- 只覆盖 chunked 响应；`Content-Length` 已知的响应上 `read(n)` 的攒批行为受底层缓冲影响，
  本条未逐一测量。
- 非流式（一次性收全再转发）的代理用 `read()` 是正确的，不必改。
