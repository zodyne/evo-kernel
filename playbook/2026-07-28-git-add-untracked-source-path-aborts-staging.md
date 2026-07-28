---
id: git-add-untracked-source-path-aborts-staging
type: lesson
status: validated
scope: global
domain: git
tags: [git, staging, move-semantics, silent-failure]
triggers:
  - "脚本里做『移动文件 + git add 新旧两个路径 + commit』"
  - "自动化提交报 commit 失败但文件确实已经改好了"
  - "git add 报 fatal: pathspec ... did not match any files"
  - "evo curate 提示『⚠ git commit 失败（条目已移动）』"
  - "同一段提交代码有时成功有时失败，差异在源文件之前是否被跟踪过"
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:dc63fb24-b5f6-455e-87c6-6bfc029de1eb
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
---

`git add -- <a> <b> <c>` 是**全有全无**的：只要其中一个 pathspec 匹配不上，整条命令 `fatal` 退出，**另外两个也不会被暂存**。

这在「移动文件后把新旧路径一起 add」的脚本里是个陷阱：旧路径能否匹配，取决于它**之前是否被 git 跟踪过**。
- 源文件已跟踪 → 文件虽已从磁盘删除，pathspec 仍匹配 index 条目，`add` 成功暂存这次删除 → 正常。
- 源文件从未跟踪（新写的临时/中间产物）→ 磁盘没有、index 也没有 → `fatal: pathspec did not match any files` → **整次暂存作废**。

所以同一段代码会「有时成功有时失败」，而差异藏在与本次操作无关的历史里。

硬证据（`bin/evo` curate，2026-07-28）：`gitCommitWithRetry(msg, [src, dest, MANIFEST])` 传入已删除的源提案路径。手写提案（从未 commit 过）走 curate 时 `git add` 报 pathspec 错误，`lessons/` 新条目与 `index/manifest.yaml` 一并没被暂存，结果只打印一句 `⚠ git commit 失败（条目已移动）`。对照实验：先 `git add ops/proposals/<file>` 让源路径进 index，再跑同一条 curate → `git committed` 正常。后台蒸馏器产出的提案因为会先被单独 commit，所以一直没暴露这个分支。

危害被两件事放大：① `add` 的异常在重试包装里只记进 `lastErr` 不中断，② `commit -q` 的 "no changes added" 提示不在捕获流里，正常路径的容错正则匹配不到 → 最终只剩一句模糊告警。**条目落盘了但没进 git**：审计链和备份（RPO=一次提交）双双落空，而调用方看到的是「已移动」这种像是成功的措辞。

做法：
- 批量 add 前先过滤 pathspec：只保留「磁盘上存在」**或**「`git ls-files --error-unmatch <p>` 通过」的路径；或者逐个 add 并容忍单个失败。
- 移动场景优先用 `git mv`（同时处理 index），或直接 `git add -A -- <dir>` 限定目录范围。
- 自动化提交的失败提示必须带上 git 的原始错误，别压成一句人话——这次的 `⚠ git commit 失败` 完全没指向 pathspec。
