---
id: split-commit-reset-soft-restore-staged
type: lesson
status: validated
scope: global
domain: git-workflow
tags: [git, commit-hygiene, staging, reset-soft, restore-staged]
triggers:
  - "一次 commit 把与主题无关的文件也带了进去"
  - "前面步骤的 git rm / git add 留在暂存区，被后续提交静默带走（失败信号）"
  - "想拆掉刚做错的本地提交，但不丢工作树与暂存现场"
  - "docs/搬迁 commit 里夹带了旧文档删除（失败信号）"
  - "需要按主题拆分提交，重写提交历史"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b3d9-1442-7475-af70-367c26fa603f
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [auto-script-git-add-all-sweeps-unrelated-files, git-add-a-verify-staged-catches-gitignore-gaps]
---

# 暂存区混入无关文件时的拆分提交：reset --soft 保留现场 + restore --staged 剔出

**主张**：一次提交把早前 `git rm`/`git add` 留下的无关改动顺手带了进去时，用 `git reset --soft HEAD~1` 撤回提交但保留工作树与暂存内容，再 `git restore --staged <无关文件>` 剔出，`git diff --cached --stat` 确认只剩目标文件后重提交。

**证据（本会话命令 ↔ 结果）**：

- 第一次 `git add docs/specs && git commit -q -F - <<'EOF'`（docs/specs 搬迁）产出提交 `c17b2b6`；但此前已执行过 `git rm -q PLAN.v1.md`，删除仍在暂存区，被这次提交一起带走。
- 修正：`git reset --soft HEAD~1 && git restore --staged PLAN.v1.md` → `git diff --cached --stat` 输出只剩 `docs/specs/*.md`（`naming.md | 237 +`、`view_tracks_3d_flow.md` 等 8 个文件），`PLAN.v1.md` 已不在暂存区。
- 重新提交得到 `2ead53b chore(docs): 搬入旧仓权威规格 docs/specs(8 文件 + 逐文件 sha256 台账)`；`PLAN.v1` 的删除进入后一个主题提交（`docs: PLAN v2 符合性审计 + 退役 v1 + core 目录去层 + 编译…`）。

**为什么**：`git commit` 提交的是整个索引，不是「本次 `git add` 的那几个文件」。长会话里跨步骤的 `git rm`/`git add` 会被后续主题提交静默带走；`reset --soft` 只移动 HEAD、不碰工作树也不碰索引内容，因此现场原样保留，只需挑选要剔出的路径，比 `--mixed` 或手工重做更不易丢改动。

**边界/反例**：本会话只处理本地未 push 的会话内提交；已 push 的历史需另行评估，不能照用。剔出后必须用 `git diff --cached --stat` 复核（本会话正是靠它确认暂存区只剩 docs/specs），或者用 `git-status-has-no-cached-flag` 里说的 `git diff --cached` 口径，而不是凭记忆断言。

## 复核证据（2026-09-22，本机 scratch 仓重演 —— 本条据此进注入集）

原提案的证据在别仓会话里、命令被截断；下列在临时仓里**完整重演**了两步，可当场重跑：

```
$ git init -q .; echo a > A.txt; echo b > B.txt; git add -A; git commit -qm init
$ git rm -q B.txt                 # 早前步骤留下的无关改动，进入暂存区
$ echo a2 > A.txt; git add A.txt
$ git commit -qm "topic: A change"
$ git show --stat --oneline HEAD
a1861ee topic: A change
 A.txt | 2 +-
 B.txt | 1 -                      ← 无关的删除被这次主题提交静默带走
$ git reset --soft HEAD~1 && git restore --staged B.txt
$ git diff --cached --stat
 A.txt | 2 +-                     ← 暂存区只剩目标文件
$ git status --short
M  A.txt
 D B.txt                          ← B.txt 的删除回到未暂存，没丢
```

**修正原提案两处**：① `docs/specs` 实际是 **9 个文件**（README + 8 个规格 md），
原提案写的「8 个文件」只是 commit message 的措辞，与 `git show --stat 2ead53b` 不符；
② 删掉「比 `--mixed` 或手工重做更不易丢改动」——`--mixed` 同样保留工作树，该比较无证据。

> **同源（n 记账）**：本条与同一会话 `01a0b3d9-1442` 的另 2 条提案同源于PLAN.v1.md 退役那一次——**一次观测被拆成多条**，别当独立经验计权。
> 更大一层：2026-09-18 那批有 3 个会话在 **33 秒内**先后启动、切片里「首条 user」逐字相同（对同一份 PLAN.md 的并行符合性审计），所以 A/B 两簇 12 条的**有效独立来源 ≈2 次**，不是 12 次。
> 另：`evo slice` 会**截断长命令**——凡依赖被截断部分的引用，只能算「当时跑过」。
