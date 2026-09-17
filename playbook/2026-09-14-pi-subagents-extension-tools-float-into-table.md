---
id: pi-subagents-extension-tools-float-into-table
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi-subagents, read-only-agents, extension-tools, exclude_extensions, hashline]
triggers:
  - "pi-subagents 只读代理（Explore/Plan）在装了注册工具的扩展后多出扩展工具"
  - "pi-subagents 的 tools: 只约束内置名，扩展工具仍浮到工具表（失败信号）"
  - "用 exclude_extensions: <包短名> 排除扩展工具"
  - "ext: 选择器一出现就变白名单"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-01-07-12-446-35gf
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: [pi-subagent-tool-silent-failure-pitfalls]
---

# 主张

pi-subagents 只读代理（Explore/Plan）在装了会注册工具的扩展后，扩展工具会浮到工具表（`tools:` 只约束内置名）。用 `exclude_extensions: <包短名>` 排除；`ext:` 选择器一出现就变白名单。

# 附：hashline 试用基线

edit 错误率 9/8-9/13 每日 8-14%（pi-stats.js 编辑段），目标 <3%。
