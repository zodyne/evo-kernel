---
id: brew-upgrade-node-preflight-global-npm-inventory
type: lesson
status: candidate
scope: global
domain: node-versioning
tags: [brew, node, npm, upgrade, preflight]
triggers:
  - "要 brew upgrade node 之前，想评估会波及哪些工具"
  - "全局 npm 装了多个 CLI（claude-code / pi / openclaw 等），升 node 怕炸"
  - "brew 升级大版本运行时（node/python）前的爆炸半径盘点"
  - "升级 node 后某个全局 CLI 莫名坏掉，怀疑原生模块 ABI 不兼容（失败信号）"
created: 2026-08-05
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fcfa6-e103-7cb4-991a-ac3e8d341a5c
last_verified: 2026-08-05
superseded_by: null
schema_version: 1
related: [node-cli-refuses-start-version-range-error]
---
`brew upgrade node` 是全有全无的运行时切换，所有全局 npm CLI 共用这一个 node：升级前先盘点——`ls /opt/homebrew/lib/node_modules/`（全局包列表）、`brew uses --installed node`（依赖 node 的 brew 包）、`find /opt/homebrew/lib/node_modules -name "*.node"`（原生模块，跨大版本 ABI 最易炸），确认爆炸半径后再升。

证据（2026-08-05 会话）：升级 node 25.8.0→26.6.0 前执行了上述三项盘点 + `npm ls -g --depth=0` 列出 7 个全局工具；升级后 openclaw 恢复运行、exit 0，未见其他全局工具损坏报告。

边界：盘点只能评估风险不能消除风险；原生 .node 模块跨大版本几乎必然要 rebuild（npm rebuild / 重装对应全局包）。本证据只覆盖 25→26 一次成功案例。
