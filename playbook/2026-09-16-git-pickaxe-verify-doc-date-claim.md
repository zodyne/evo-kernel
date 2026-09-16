---
id: git-pickaxe-verify-doc-date-claim
type: lesson
status: validated
scope: global
domain: git
tags: [git, pickaxe, git-log, doc-drift, date-claim, version-claim]
triggers:
  - "核对文档里「某日期/某版本起」这类自述断言是否属实（评审/走查/验收）"
  - "怀疑 CLAUDE.md / README / ADR 里写的日期或版本号与实际提交对不上"
  - "想知道某段描述、某日期串是哪个 commit 写进文件的"
  - "翻了半天 git log 提交历史也定位不到「这句话是哪次提交引入的」（失败信号）"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a736-a3ba-7353-8a3d-430f03b57114
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
---

# 核对文档日期/版本断言：git log -S（pickaxe）定位断言串的引入 commit

## 主张
核对文档里「某日期/某版本起」这类自述断言时，别信文档自述，用 `git log -S '<断言串>' -- <文件>`（pickaxe）定位该串首次出现的 commit，以该 commit 的实际提交日期对拍——文档自述日期可能滞后或超前于真实提交。

## 为什么
`git log -S <str>` 按「字符串出现次数的变化」搜索提交，能直接回答「这句话/这个日期串是哪次提交写进文件的」。文档里「2026-09-15 起」这类断言，本质是一次提交引入的一串文本；用 pickaxe 找引入它的 commit，其 commit date 才是真相。文档自述日期是人力维护的元数据，容易与真实提交错位（尤其批量改日期、同步文档时）。

## 证据（本会话命令对照：验证「CLAUDE.md 写 2026-09-15」与 ADR 自述 2026-09-12 是否属实）
- `git log --pretty='%h %ad %s' --date=short -S '2026-09-15' -- CLAUDE.md` → 返回 `1c0c2f0 2026-09-12 refactor(doa): beam 与 dbf2d 兼并`，证明文档写的「2026-09-15」实际是 2026-09-12 那次提交引入的。
- `git log --pretty='%h %ad %s' --date=short -S 'F7 起(2026-09-14)' -- CLAUDE.md` → 返回 `0d40753 2026-09-10 feat(afm761)...`，同法验证另一条日期断言，同样证得文档日期超前于真实提交。
- 旁证：`git show 1c0c2f0:CLAUDE.md | grep -n '2026-09-1[0-9]'` 与 `git show --stat --name-only c5478de | grep -i claude`（输出 `CLAUDE.md NOT in c5478de`）用于抽查某 commit 时文件是否真的含/不含该串，排除「改错了 commit」的误判。

## 边界 / 反例
- `-S` 匹配的是「字符串出现次数变化」，若断言串在多处出现或被复制迁移，会返回多个 commit——按时间序取最早那次，并配合 `git show <commit>:<file>` 抽查该 commit 时文件实际内容。
- 若断言串是版本号且被多次重写，`-S` 同样返回多个 commit，要的是「首次引入」，不是最后一次修改。
- 本技术只回答「某串何时引入」；不用于验证「文档自述统计数字（命令数/测试数/条目数）是否准确」，那属于 doc-selfreported-counts-drift 的领域。
- 若文件不是纯文本、或被 gitignore 从未纳入版本控制，`-S` 无历史可查。
- 2026-09-16 独立复验（交互模型，非原会话）：在另一仓库 `git log -S 'readReconcileDedup' -- bin/evo` → `1302130 2026-09-16 fix: 对账去重…`，首次引入 commit 定位正确。
