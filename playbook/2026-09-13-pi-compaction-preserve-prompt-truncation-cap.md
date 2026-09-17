---
id: pi-compaction-preserve-prompt-truncation-cap
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, compaction, truncation, reserveTokens, fast-compaction, summary]
triggers:
  - "pi 压缩（compaction）每次耗时 4-6 分钟、输出恰好撞上限被截断"
  - "pi 原版 UPDATE 摘要 prompt 'PRESERVE all existing information' 导致摘要只增不减"
  - "compaction.usage.output 是否恰好等于 0.8×reserveTokens=13107（诊断口径）"
  - "fast-compaction 的 SUMMARY_MAX_TOKENS=4096 与长度纪律实测效果"
  - "压缩摘要尾部 Next Steps 先丢（失败信号）"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-13-02-03-55-596-0r8e
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
related: []
---

# 主张

pi 压缩慢的第二层原因：pi 原版 UPDATE 摘要 prompt 写着 `PRESERVE all existing information`，使摘要只增不减，最终每次撞 `0.8×reserveTokens=13107` 上限被截断（尾部 Next Steps 先丢），高峰 ~50 tok/s 一次 4-6 分钟。

fast-compaction 改 `SUMMARY_MAX_TOKENS=4096` + 长度纪律后实测 3544 tok/22s。

# 诊断方法

从 session jsonl 的 `compaction.usage.output` 看是否恰好等于上限。
