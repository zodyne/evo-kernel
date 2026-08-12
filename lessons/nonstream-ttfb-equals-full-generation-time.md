---
id: nonstream-ttfb-equals-full-generation-time
type: lesson
status: candidate
scope: global
domain: llm-ops
tags: [streaming, ttfb, timeout, llm-api, thinking]
triggers:
  - "用首字节延迟（TTFB）给 LLM 请求做判活/超时设计"
  - "非流式（stream=false）LLM 请求长时间没有响应"
  - "开 thinking/推理模式后 API 响应慢到触发看门狗（失败信号）"
  - "包装 LLM API/CLI 做批处理，在流式与非流式之间选型"
  - "实测 TTFB 与总耗时几乎相等，判活逻辑形同虚设"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:b6cf7fd7-73c7-4cef-b538-5428b694a71b
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [llm-cli-zero-output-slow-not-dead, streaming-protocol-snapshot-vs-delta]
---

# 非流式 LLM 请求的首字节延迟≈全量生成时长：判活与看门狗必须建在流式首字节上

## 主张

对非流式（stream=false）LLM 请求，**首字节延迟就是整个生成时长**——服务端生成完才返回
第一个字节。任何「按首字节判活 / 按 TTFB 设超时」的逻辑在非流式下完全失效，
退化成「按完整生成时长超时」。长任务（大输入、thinking 模式）必须改用流式，
并把判活信号建在**流的首个事件**上；看门狗分两段：首事件超时（短，判死）+
总时长超时（长，判慢）。

## 为什么

2026-07-29 直连 kimi（anthropic-messages 契约）实测，同一份 26KB / 约 9349 tokens 输入：

| 配置 | 首字节 | 总耗时 | 事件数 |
|---|---|---|---|
| 非流式 + thinking | **90.07s** | **90.44s** | — |
| 流式 + thinking | **7.17s** | 31.47s | 603 |

非流式下 TTFB 与总时长的差值仅 0.4s（纯传输时间）——「服务完全健康」，
但任何 <90s 的 TTFB 看门狗都会误杀一个正常请求；流式下 7s 即可确认存活，
31s 完成全部生成。这正是同日下午 pi 批处理「零输出挂死」误判的底层机制
（见 related 的 slow-not-dead 条目）。

## 反例 / 边界

- 流式的代价：消费端要处理事件流，整段保留中间事件会让内存/文件暴涨
  （见 related 的 snapshot-vs-delta 条目）。
- 秒级生成的短任务非流式足够，不必为用流式而流式。
- TTFB 短 ≠ 总时长短：流式确认存活后仍要防「流挂着不动」——需要帧级空闲超时，
  本条未实测，列为边界。

## 证据

- 两次直连计时（curl 级，绕过 pi）：非流式 90.07s/90.44s、流式 7.17s/31.47s/603 事件，
  均 HTTP 200。
