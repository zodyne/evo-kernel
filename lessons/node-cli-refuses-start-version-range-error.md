---
id: node-cli-refuses-start-version-range-error
type: lesson
status: candidate
scope: global
domain: node-versioning
tags: [node, brew, openclaw, semver, engine-check]
triggers:
  - "brew/npm 全局装的 Node CLI 突然起不来、命令无输出或报错退出"
  - "工具自己升级后开始报 Node.js 版本不满足（失败信号：Node.js >=x <y is required）"
  - "报错信息里列出多个版本区间（>=22.22.3 <23, >=24.15.0 <25 ...），当前版本只差一个 minor"
  - "排查『昨天还能用今天不能跑』的 node 工具，第一步不知道查什么"
created: 2026-08-05
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fcfa6-e103-7cb4-991a-ac3e8d341a5c
last_verified: 2026-08-05
superseded_by: null
schema_version: 1
related: [brew-upgrade-node-preflight-global-npm-inventory, pyside6-old-version-fails-on-new-python]
---
Node CLI 启动脚本可能强制 semver engine 检查：工具自身升级提高最低 node 版本后，旧 node 只差一个 minor 也会被**直接拒绝启动**；第一步就跑 `<tool> --version`，报错里会**直接列出所有接受的版本区间**，照着对齐 node 版本即可，不用猜。

证据（2026-08-05 会话）：`openclaw --version` 报 `Node.js >=22.22.3 <23, >=24.15.0 <25, or >=25.9.0 is required (current: v25.8.0)`——系统 node 25.8.0 距最低要求只差 0.1。`brew upgrade node` 到 26.6.0 后 `openclaw --version` 正常输出版本、exit 0。

边界：前提是报错信息给出了明确区间（engine check 主动拒绝）；若是启动后崩溃/静默退出则另查日志。降级 node 到区间内版本也是合法解，升级不是唯一出路。
