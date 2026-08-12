---
id: git-mv-untracked-source-fatal
type: lesson
status: candidate
scope: global
domain: git
tags: [git, git-mv, untracked, repo-reorganization, fatal]
triggers:
  - "在刚 git init 的仓库里做目录重组（mkdir 新结构 + 批量移动文件）"
  - "git mv 报 fatal: not under version control（失败信号）"
  - "命令链里混用 git mv 和普通 mv，执行到一半中断"
  - "移动文件后 git status 出现 D + 未跟踪新路径，而不是预期的 R(rename)"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fab8d-651f-7df8-8d1d-29c7d2f71bce
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [git-add-untracked-source-path-aborts-staging, 2026-07-27-git-mv-bulk-verify-byte-identical-renames]
---

**主张**：`git mv` 的源文件**必须已被 git 跟踪**；对未跟踪文件它直接 `fatal: not under version control` 退出。在刚 `git init`（一切未跟踪或部分跟踪）的仓库做目录重组时：**未跟踪文件用普通 `mv`，已跟踪文件用 `git mv`**，按文件逐个区分，不要在一条命令链里无脑全用 `git mv`。

**证据**：会话中 `git init` 后建任务分支做目录重组，命令链里的 `git mv residual_floor.mat ...` 报 `fatal: not under version control, source=residual_floor.mat, destination=...` 中断；改为 `mv residual_floor.mat archive/quality-filter/ && git mv quality_filter_residual_v2.m ...`（未跟踪走 mv、已跟踪走 git mv）后重组完成，提交记录里已跟踪文件正确显示为 `rename ... (99%)`。

**边界**：与 `git-add-untracked-source-path-aborts-staging`（pathspec 全有全无）互补：git 一族命令对"未跟踪路径"都是硬失败而非降级。批量重组前可先 `git ls-files` 列出已跟踪集合，脚本里按集合分流 mv/git mv。
