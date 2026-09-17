---
id: pi-provider-name-isdeepseek-max-tokens-field
type: lesson
status: validated
scope: global
domain: harness-config
tags: [pi, provider, deepseek, maxTokensField, max_completion_tokens, max_tokens, compaction, new-api]
triggers:
  - "pi 自建网关下压缩摘要输出上限静默失效、agent 变慢"
  - "provider 名不叫 deepseek（如 deepseek-internal）导致 pi 的 isDeepSeek 检测不匹配"
  - "models.json compat 里 maxTokensField 该写 max_tokens 还是 max_completion_tokens"
  - "单次 compaction 烧掉几万 output token、耗时几十分钟（失败信号）"
  - "new-api 网关只认 max_tokens，pi 发的却是 max_completion_tokens"
created: 2026-09-10
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-10-07-36-02-748-l8kq
last_verified: 2026-09-10
superseded_by: null
schema_version: 1
related: []
---

# 主张

pi agent 慢的根因（2026-09-10 suc221）：自建网关 provider 名 `deepseek-internal` 不匹配 pi 的 `isDeepSeek` 检测（只认 `provider==='deepseek'` 或 baseUrl 含 `deepseek.com`），导致 `compat.maxTokensField` 落到 `max_completion_tokens`，而 new-api 网关只认 `max_tokens`——pi 给压缩摘要设的 13107 输出上限静默失效。

修法：`models.json` 的 compat 显式写 `maxTokensField=max_tokens` + 降 thinking。

# 为什么

provider 名不落在检测集合里，`compat.maxTokensField` 就不会取 `max_tokens` 值；网关只认 `max_tokens`，于是上限字段被忽略、静默失效。叠加 `thinkingLevel=max` 被压缩流程继承（`compact()` 传 `this.thinkingLevel`），单次压缩烧了 41741 output（其中 36721 reasoning）@24tok/s = 29 分钟。

# 证据

- 单次压缩：41741 output（36721 reasoning）@24tok/s = 29 分钟。
- 证据出处：`~/.pi/agent/sessions/*/*.jsonl` 的 compaction 条目带 `usage` / `tokensBefore`。
