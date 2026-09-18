---
id: related-must-not-link-proposal-ids
type: lesson
status: candidate
scope: project:evo-kernel
domain: evo-kernel
tags: [related, dangling-link, proposal, fold, audit, frontmatter]
triggers:
  - "把重复提案折进已有条目（fold/merge）后，想给目标条目记一笔『并入自哪条提案』"
  - "要给条目的 related: 增删 id，而那个 id 来自 ops/proposals/ 下的提案文件"
  - "`evo audit` 报 related 指向不存在的 id（MID），而该 id 是刚被删掉的提案 slug（失败信号）"
  - "顺着某条条目的 related 跳转，跳到的是已删除的提案文件（失败信号：导航断链）"
  - "批量 fold/清理提案后只跑了 YAML 解析检查就收尾，没跑 evo audit（失败信号：悬挂引用全漏过）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b383-7dcf-73b1-bdd8-c2e67725891a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [archived-entry-inbound-related-sweep, proposal-fold-ledger-not-delete-count]
---

**主张**：`related:` 只写**当时存在于 SCAN_DIRS（lessons/playbook/facts/episodes/principles）里的条目 id**；折叠重复提案时，不要为了记「并入自哪条提案」把被折提案的 id 追加进目标条目的 `related:`——提案文件就在同一个动作里被 `rm` 掉（`ops/proposals/` 既不在 SCAN_DIRS，也不在 `evo catalog` 的覆盖内），链接当场变成悬挂引用，`evo audit` 报 MID；而 related 的用途是导航，指向已删提案只会跳空。来历（本条并入了哪条提案）应写进正文或 commit message。

**为什么**：`related` 是纯文本 id 引用，不随被引用对象消失而自清（SCHEMA 建链规则已写明「被链条目一旦 archive 或改 id，悬挂链接比没链接更误导」）；而提案是短生命周期对象——折完即删、被拒不入库。把一个注定要消失的 id 当条目链接写进去，等于预埋断链。

**证据（session 01a0b383）**
- 切片「命令 ↔ 结果」：`rm ops/proposals/2026-09-18-entry-id-grep-hits-referrers-not-definition.md ops/proposals/2026-09-18-nvim-server-socket-under-tmpdir-not-tmp.md` → `deleted`；同一切片「写/改文件」列出 `lessons/2026-09-18-entry-id-grep-hits-bench-labels.md` 与 `playbook/2026-09-07-debug-nvim-lsp-via-live-server-socket.md`。
- 该会话的收尾 commit `6d7b876`（2026-09-18 15:56:02 +0800；会话文件时间戳 `2026-09-18T07-55-34Z` = 15:55:34 +0800，同一会话时间窗）在 fold 这一次提交里给这两个条目的 `related:` 各追加了一个被删提案的 id：`related: [..., entry-id-grep-hits-referrers-not-definition]`、`related: [..., nvim-server-socket-under-tmpdir-not-tmp]`。
- 同一状态跑 `evo audit` 直接命中两条：`MID [entry-id-grep-hits-bench-labels] related 指向不存在的 id: entry-id-grep-hits-referrers-not-definition → 修正或删除该链接`、`MID [debug-nvim-lsp-via-live-server-socket] related 指向不存在的 id: nvim-server-socket-under-tmpdir-not-tmp → 修正或删除该链接`。

**反例 / 边界**
- 与 `archived-entry-inbound-related-sweep` 同症状（audit MID）、不同成因：那条是**目标先消失、入链没扫**（归档/改名后忘了全库扫 inbound）；本条是**写入时就把注定消失的提案 id 当成了条目**——建链与删除在同一动作里，所以要在写 `related` 那一步就拦住，而不是事后扫。
- 「留追溯」本身没错，错的只是载体：写进正文（如「本条并入自提案 X」）或 commit message（本会话 `6d7b876` 的 body 就是逐条台账）都不会进 `evo audit` 的 id 存在性检查。
- 检测口径：YAML/frontmatter 解析检查**抓不到**悬挂引用——本会话收尾正是只做了 yaml 解析（切片第 3 条命令 → `OK ... | id= ... | last_verified= ...`），两条 MID 全部漏过；要抓只能跑 `./bin/evo audit`，或对 `^related:` 做全库 id 存在性对账。
- 唯一的「复活」例外：提案若最终以原 id 入库（`curate` 保留 id、只给文件名加日期前缀，如 `proposal-fold-ledger-not-delete-count` → `lessons/2026-09-18-proposal-fold-ledger-not-delete-count.md`），该链接会重新变有效——但 fold 场景下提案是被删掉的，不存在这条出路。
- 本次已经产生的两条悬挂链接是既成事实：修法是删掉这两个 related 元素（或改指现存条目 id），不要指望它们自愈。
