---
id: claude-plugin-official-marketplace-not-preregistered
type: lesson
status: validated
scope: global
domain: claude-code
tags: [claude-code, plugin, marketplace, install]
triggers:
  - "claude plugin install 报 not found in marketplace claude-plugins-official"
  - "claude plugin marketplace update 报 Marketplace not found"
  - "想装 claude-plugins-official 官方市场里的插件"
  - "plugin-catalog-cache.json 有数据但市场未注册（失败信号）"
  - "claude plugin marketplace add anthropics/claude-plugins-official"
created: 2026-08-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-18-21-57-43-065-g92l
last_verified: 2026-08-18
superseded_by: null
schema_version: 1
related: []
---

# 主张

Claude Code 内置市场 `claude-plugins-official` **并未预注册**：CLI 直接 install 会报「not found in marketplace claude-plugins-official」并建议 marketplace update，但 update 也报「Marketplace not found」——**错误信息误导**。

正解：先 `claude plugin marketplace add anthropics/claude-plugins-official`（走 SSH clone），再 install。

# 为什么容易误判

`/plugin` 交互界面能独立抓官方目录，所以 `~/.claude/plugins/plugin-catalog-cache.json` 有数据**不代表**市场已注册——缓存与市场注册是两件事。

# 证据

capture `capture-2026-08-18-21-57-43-065-g92l` 原文（未改写）：「Claude Code 内置市场 claude-plugins-official 并未预注册：CLI 直接 install 会报『not found in marketplace claude-plugins-official』并建议 marketplace update，但 update 也报『Marketplace not found』——错误信息误导。正解是先 claude plugin marketplace add anthropics/claude-plugins-official（走 SSH clone），再 install。/plugin 交互界面能独立抓官方目录，所以 ~/.claude/plugins/plugin-catalog-cache.json 有数据不代表市场已注册。」capture 内为 CLI 实测现象与正解命令，证据等级 command。
