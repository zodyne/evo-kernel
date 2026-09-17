---
id: novasky-deepseek-max-tokens-param-ceiling
type: fact
status: validated
scope: global
domain: llm-tooling
tags: [nanoradar, deepseek, max-tokens, api-limit]
triggers:
  - "给 NovaSky 网关配 deepseek max_tokens 时不知道上限"
  - "max_tokens 设太大报 HTTP 400"
  - "deepseek-v4-flash 的 max_tokens 参数能设到多大"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a3ff-16b7-73aa-b447-07d4b5ec2022
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [pi-contextwindow-960k-gateway-probe, nanoradar-gateway-throughput-time-of-day]
---

# NovaSky 网关 deepseek-v4-flash 的 max_tokens 参数硬上限在 262144 与 524288 之间

**主张**：NovaSky 网关对 deepseek-v4-flash 的 `max_tokens` 请求参数有独立硬上限，落在 262144 与 524288 之间——`max_tokens=262144` 返回 HTTP 200，`max_tokens=524288` 起返回 HTTP 400。

**为什么**：这是网关对 max_tokens 参数的校验上限，与 contextWindow / prompt 长度是两回事（官方宣传的 1M context 不适用于这个参数）。配置 provider 的 maxTokens 时别误以为能设到官方 context 上限，超了直接 400。

**边界**：数值是 2026-09 实测快照，网关可能调整；只对 NovaSky 网关的 deepseek-v4-flash 生效。本机 pi 实际配置 maxTokens=131072，远低于上限，不触发。

**证据**：slice 探针命令↔结果——`for mt in 262144 524288 1048576 2000000`：262144 → HTTP 200（finish=stop, completion_tokens=19），524288 及更大 → HTTP 400。
