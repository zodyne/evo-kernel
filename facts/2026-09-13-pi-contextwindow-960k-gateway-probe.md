---
id: pi-contextwindow-960k-gateway-probe
type: fact
status: validated
scope: global
domain: harness-config
tags: [pi, contextWindow, keepRecentTokens, probe, urllib, curl, funnel]
triggers:
  - "把 pi contextWindow 从默认 128k 调大（如 960k）的取舍与留余量"
  - "novasky 网关 curl 探针 203k/409k/984k prompt tok 是否放行"
  - "每步上传整段历史 JSON，走 Funnel 每步 +7s"
  - "Python urllib 大 body 报 write timeout，探针要用 curl（失败信号）"
  - "压缩后 keepRecentTokens 调到 60k 抵消 4k 摘要"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-13-04-49-51-301-3z1j
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
related: []
---

# 主张

pi 的 `contextWindow` 已从默认 128k 设到 960k（deepseek-v4-flash 官方 1M）：novasky 网关 curl 探针 203k/409k/984k prompt tok 全部 200，未命中预填 3.1k→1.2k tok/s 随长度下降；不设满 1M 是给门限 + maxTokens 留余量。

# 代价与配套

- 每步上传整段历史 JSON，1M≈7MB，走 Funnel 时每步 +7s，LAN 无感。
- 压缩后 `keepRecentTokens` 提到 60k，抵消 4k 摘要盖 950k 历史的粗糙。
- Python urllib 大 body 会报 write timeout，探针用 curl。
