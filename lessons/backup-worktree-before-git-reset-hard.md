---
id: backup-worktree-before-git-reset-hard
type: lesson
status: candidate
scope: global
domain: git
tags: [git, backup, reset, worktree, safety]
triggers:
  - 要对脏工作树跑 git reset --hard / git clean -fdx
  - 接手别人的克隆仓库，要把工作树清回 origin 状态
  - 工作树里有未提交改动 + 未跟踪新文件，准备一次性丢弃
  - reset 之后才发现丢掉的改动里还有要用的东西
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:da720f38-036f-42ec-820d-ce8538a4fc1f
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [backup-untracked-file-before-edit]
---

# git reset --hard + clean -fdx 前：tar 打包整个工作树 + git diff 落盘到仓库外

`git reset --hard <ref> && git clean -fdx` 同时销毁**已跟踪文件的未提交改动**和**全部未跟踪/被忽略文件**，两路都不可恢复。跑之前做两件事，都放到**仓库外**的目录：

1. `tar -czf <外部目录>/backup.tgz <工作树内容>`（连未跟踪文件一起）；
2. `git diff > <外部目录>/worktree.diff`（已跟踪改动的可读形态，方便后续 `awk '/^diff --git/'` 按文件捞取）。

**证据**（session da720f38）：对 libucm221 克隆先做了 tar 备份 + 3545 行 diff 落盘，再 `git reset --hard origin/dev && git clean -fdx`；随后从备份 `tar -x` 解出并把 `faf.h/faf.c/fpga_frame.*` 等文件 `cp` 回新分支继续工作——备份当天就被实际用到，不是摆设。
