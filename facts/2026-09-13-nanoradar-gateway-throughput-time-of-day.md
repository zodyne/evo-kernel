---
id: nanoradar-gateway-throughput-time-of-day
type: fact
status: validated
scope: global
domain: harness-config
tags: [gateway, throughput, tok-per-s, contextWindow, deepseek-v4-flash, pi]
triggers:
  - "分析 pi 变慢，想先看网关吞吐是否随时段波动"
  - "novasky/nanoradar 网关吞吐 5× 波动（按小时分桶看 tok/s）"
  - "models.json 未写 contextWindow 时 pi 默认多少（128k）"
  - "deepseek-v4-flash 官方 1M vs 网关探针 203.5k 放行"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-13-02-03-55-671-xev0
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
related: []
---

# 主张

novasky/nanoradar 网关吞吐随时段 5× 波动。分析 pi 慢时先按小时分桶看 tok/s，再谈配置。

# 实测数字

- 北京 07-10 点 / 周六早：140-245 tok/s
- 11-14 点：45-53 tok/s
- 20-24 点：27-50 tok/s

# 附：contextWindow 默认与探针

- `models.json` 未写 `contextWindow` 时 pi 默认 128k。
- deepseek-v4-flash 官方 1M，网关探针 203.5k 放行（65s 预填），已设 200000。
