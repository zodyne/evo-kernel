---
id: pi-tools-allowlist-filters-extension-tools
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, tools-allowlist, extension, hashline, cohort, gauntlet]
triggers:
  - "pi --tools 允许表是否对扩展工具生效"
  - "装了 pi-hashline-edit-pro 后 pi-cohort/gauntlet 的 implementer 只剩 write 整文件（失败信号）"
  - "pi-cohort 子代理以独立 pi 进程 + --tools read,write,edit,... 启动时扩展工具被过滤"
  - "hashline 与 cohort/gauntlet 兼容性"
  - "replace/insert 不在工具允许表里，扩展的 edit 被停用"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-09-14-01-07-12-372-i6hj
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: [pi-subagent-tool-silent-failure-pitfalls]
---

# 主张

pi 工具允许表（`--tools`）对扩展工具同样生效（`agent-session._refreshToolRegistry` 的 `isAllowedTool` 过滤 builtin+extension）。

# 后果

pi-cohort 子代理以独立 pi 进程 + `--tools read,write,edit,...` 启动；装了 pi-hashline-edit-pro 后 `edit` 被停用，`replace`/`insert` 不在允许表 → gauntlet 的 implementer 只剩 write 整文件。hashline 与 cohort/gauntlet 当前不兼容。
