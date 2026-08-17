---
id: llm-cli-zero-output-slow-not-dead
type: lesson
status: deprecated
scope: global
domain: llm-ops
tags: [pi, watchdog, timeout, troubleshooting, root-cause]
triggers:
  - "pi -p / LLM CLI 长时间零输出，看起来像挂死"
  - "后台批处理调 LLM：大输入任务全部超时零输出、小 prompt 却秒回（失败信号）"
  - "进程 CPU 时间接近 0、阻塞在 I/O——像挂了但其实是慢"
  - "怀疑 provider 故障之前，还没有直连 API 计时验证过"
  - "给 LLM 调用写看门狗/超时，阈值凭感觉定的"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:b6cf7fd7-73c7-4cef-b538-5428b694a71b
last_verified: 2026-07-29
superseded_by: skill:external-cli-polling
schema_version: 1
related: [evo-distill-transient-connection-error-retry, nonstream-ttfb-equals-full-generation-time, overturned-capture-must-be-rewritten]
---

# LLM CLI 长时间零输出多半是「慢」不是「死」：先查看门狗与任务耗时的关系，别先怪 provider

## 主张

LLM CLI（`pi -p` 这类）在大输入 + thinking 下长时间零输出时，**默认假设应该是
「任务生成时长超过了调用方看门狗」，而不是「提供侧故障」**。定性方法分两步：
杀掉任务后用小 prompt 探活（区分进程级死锁与任务级慢）；再**直连 provider API
对同等体量输入计时**。只有直连也失败，才轮到 provider 归因。
看门狗阈值必须由实测任务耗时分位数来定，不能凭感觉。

## 为什么

2026-07-29 一下午的误判链：pi -p 跑提案评审——100KB 内联包 38 分钟只用 0.89s CPU
（阻塞 I/O 非计算）；拆成 26KB 三批仍各 10 分钟超时零输出；换小 prompt+tools 形态
8 分钟零输出。当时归因为「对大任务一律挂死/提供侧问题」并 capture。
但杀掉进程后小 prompt 探活秒回（EXIT=0）；直连 kimi API（pi 实际用的
anthropic-messages 契约）对 26KB 输入实测：非流式带 thinking HTTP 200，
首字节 90.1s、总 90.4s——**provider 全程健康**。真实根因：评审任务的生成时长
超过看门狗（600s），进程每次都在产出第一个字节前被杀。
结论反转后，早先的错误 capture 被删除重写（见 related）。

## 反例 / 边界

- 若直连 API 也 4xx/5xx/超时，则确属提供侧——此时参照 related 的瞬时错误条目：
  先重跑，别改实现。
- 「小 prompt 探活正常」推不出「大任务也会正常」——探活只证明进程与通路活着。
- CPU 近 0 + I/O 阻塞是「慢」的典型特征，但不能区分「慢」与「连接挂起」，
  要结合直连计时确认。

## 证据

- 探活：`pi -p --no-session -nt "只回答两个字：可用"` → 输出「可用」EXIT=0。
- 直连计时：26KB（约 9349 tokens）非流式 thinking → HTTP 200，TTFB 90.07s / 总 90.44s；
  流式 → TTFB 7.17s / 总 31.47s。
- 症状记录：38 分钟进程 CPU 仅 0.89s；多个批次 600s 超时零输出。
