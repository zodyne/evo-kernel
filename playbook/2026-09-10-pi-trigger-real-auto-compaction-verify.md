---
id: pi-trigger-real-auto-compaction-verify
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, compaction, verification, session-jsonl, print-mode, fromHook]
triggers:
  - "想触发一次真实 auto-compaction 来验证 pi 扩展或压缩改动"
  - "pi -p 里跑 /compact 没有执行、被当成普通用户消息发给模型（失败信号）"
  - "想用 pi --session <copy> -p 配合 read 工具把上下文顶过门限触发压缩"
  - "怎么看 compaction 是否被扩展接管（fromHook=true）、思维链是否关掉（usage.reasoning=0）"
  - "尾部上下文接近门限（contextWindow-reserveTokens=111616）想复现自动压缩"
created: 2026-09-10
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-10-07-57-02-553-dthb
last_verified: 2026-09-10
superseded_by: null
schema_version: 1
related: [pi-extension-command-print-json-mode-unavailable]
---

# 主张

想触发一次真实 auto-compaction 做验证，用「复制一份接近门限的 session jsonl + 用 read 工具把上下文顶过门限」这条路径，不要去 `pi -p` 里跑 `/compact`。

# 具体做法

1. `/compact` 在 `pi -p` 打印模式不被当命令执行，会当成普通用户消息发给模型，白花一次调用。
2. 可行做法：`cp` 一份尾部上下文接近门限（`contextWindow-reserveTokens=111616`）的 session jsonl 到临时目录，再 `pi --session <copy> -p '读一下 README.md 并总结'`——用 read 工具把上下文顶过门限，压缩就会在 turn 结束后自动触发。
3. 证据看 jsonl 里新增的 compaction 条目：`fromHook=true` 说明扩展接管成功，`usage.reasoning=0` 说明思维链确实关掉了。
