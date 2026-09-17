---
id: pi-gauntlet-personas-symlink-agents-dir
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi-gauntlet, pi-subagents, personas, symlink, agents-dir]
triggers:
  - "装了 pi-gauntlet 后 Agent 工具类型里出现重复 persona（双份列出）"
  - "pi-gauntlet postinstall 把 persona .md 软链进 ~/.pi/agent/agents/"
  - "pi-subagents 扫描 agents 目录，与 gauntlet 的 persona 混在一起（失败信号）"
  - "装卸 gauntlet 时要检查 agents 目录里的软链"
  - "7 个 persona 同时成为 Agent 工具类型，可从错误机制派发"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-09-14-01-07-12-409-8c57
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: [pi-subagent-tool-silent-failure-pitfalls]
---

# 主张

pi-gauntlet postinstall 把 7 个 persona `.md` 软链进 `~/.pi/agent/agents/`，而 pi-subagents 也扫这个目录 → 这些 persona 同时成为 Agent 工具的类型（双份列出、可从错误机制派发）。

# 处置

装/卸 gauntlet 时检查 agents 目录里的软链。
