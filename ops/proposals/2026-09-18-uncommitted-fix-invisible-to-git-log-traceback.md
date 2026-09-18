---
id: uncommitted-fix-invisible-to-git-log-traceback
type: lesson
status: candidate
scope: global
domain: git
tags: [git, forensics, traceback, uncommitted, working-tree, incident-review]
triggers:
  - "事后追溯『这次事故到底修了什么、改在哪』的修复溯源调查"
  - "git log / git log -- <file> 里找不到预期的修复提交（失败信号）"
  - "要判断某个配置/代码修复是否已入库、能否用 git 回滚"
  - "git status 显示目标文件是 ` M` 而提交历史里没有对应改动（失败信号）"
  - "只改了工作区没提交的修复，几天后复盘时无法用 git 定位"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ab-4e97-725c-a75a-f987209df0c2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# 修复溯源不能只查 `git log`：修复可能只活在工作区（`git status -- <file>` 先判在不在提交里）

## 主张

做事故修复溯源时，「修复是什么/在哪」分两种形态，必须先用 **`git status --short -- <file>`** 判一次，再决定怎么找：

- **已入库** → `git log -- <file>` / `git show` / `git blame` 能拿到修复及其引入时间；
- **只在工作区（` M` / `??`）** → `git log` 无论翻多少条都看不到它，只能靠工作区 diff 辨认，而且**不可回滚**（没有历史对象），一旦被 checkout/stash/clean 抹掉就再也找不回。

只查 `git log` 就下「没有修复 / 修复没做过」的结论，是这次会踩的坑。

## 为什么

`git log` 读的是提交历史；工作区里已修改未暂存的文件与 HEAD 不同，但尚未成为任何提交。用户/自己「临时改一下先跑起来」的配置类修复，恰恰最常停在这个状态——它对运行中的程序**已经生效**，却对 git 溯源**完全隐身**。修重要、提交不重要的那一步，正好发生在事故刚复现、注意力全在修的时候。

## 证据（本会话切片命令 ↔ 结果）

- 修复件：flatten.nvim 里新增的 `no_files` 钩子，文件 `~/.config/nvim/lua/plugins/init.lua`（真身 `/Users/zodyne/Dev/dotfiles/config/nvim/lua/plugins/init.lua`）第 36-46 行（末条 assistant 结论）；`rg -n "no_files"` 在真身配置里命中第 44 行。
- `$ echo "=== git status of the fix file (committed?) ==="; git -C /Users/zodyne/Dev/dotfiles status --short -- config/nvim/lua/plugins/init.lua` → ` M config/nvim/lua/plugins/init.lua` —— 修复是「已修改、未暂存」，不在任何提交里。
- `$ git -C /Users/zodyne/Dev/dotfiles log --date=iso --pretty='%h %ad %s' -8 -- config/nvim/lua/plugins/init.lua` → 该文件最后一次提交是 `b8a8e60 2026-09-04 13:11:15 +0800 fix(nvim): nvim-lspconfig 显式 lazy=fa...` —— 事故（2026-09-14）之后没有新提交，修复在历史里查不到。
- 旁证（不是「仓库没在提交」）：`git -C ... log --pretty='%h %ad %s' -50` 里 09-15 有别的提交 `f035986 2026-09-15 14:32:10 chore(nvim): 移除 PDF 内嵌阅读器前的备份快照` —— 同仓库在提交，唯独这条修复没被提交。

## 边界 / 反例

- ` M` 只证明「与 HEAD 不同」，**不等于**「这就是本次事故的修复」——仍要 `git diff -- <file>` 核对改动内容与修复描述是否对得上。
- 若目标是 `??`（untracked），连 diff 基线都没有；此时若还想回滚/对比，只能另找原件（备份副本、上游源码、文件系统快照）。
- 追溯的是「已入库的修复」时，本条不增加信息；`git log -- <file>` 就够用。
- 一旦确认修复只在工作区，**先固化证据（把 `git diff` 落盘/另行备份）再做其他 git 操作**——否则后续任何 checkout/stash/clean 都会把唯一副本清掉。

## 失败信号（未来命中即该想起本条）

- `git log -- <file>` 最新提交早于事故时间，但 `git status -- <file>` 是 ` M` → 修复在工作区、不在历史里。
- 打算用 `git log` 的空结果断言「这个修复从没被做过」。
- 复盘时发现修复「生效了但说不清哪次改的、也回滚不了」。
