---
id: auto-script-git-add-all-sweeps-unrelated-files
type: lesson
status: validated
scope: global
domain: git-workflow
tags: [git, commit, automation, working-tree, hygiene]
triggers:
  - "在脚本/工具里写 git commit，想只提交本次动过的几个文件"
  - "提交后发现探针文件 / 临时调试产物 / 别人的并行改动被卷进了 commit"
  - "gitCommitWithRetry / 自动化提交函数用 git add -A 或 git add ."
  - "commit 的 diff 出现了本次逻辑没碰过的文件（失败信号）"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# 自动化提交脚本不要用 `git add -A`，要显式暂存本次动过的文件列表

**主张**：封装在工具里的提交函数（如 `gitCommitWithRetry(msg)`）若用 `git add -A`，会把调用瞬间工作区里**所有**已改/未跟踪文件卷进提交——包括探针、临时调试产物、同会话其他并行改动。提交边界失守后，单个逻辑变更无法干净回滚，bisect/cherry-pick 也被污染。

**根因**：`-A` 是"全工作区快照"，而工具函数的语义意图是"提交我这次告诉你的文件"。两者在调用方有未预期的工作区状态时必然背离。

**修法**：提交函数接收显式文件列表参数 `gitCommitWithRetry(msg, [files])`，内部 `git add -- <files...>` 只暂存这些路径；调用点把本次真正动过的文件传进去。

**反例/边界**：手动 `git commit -am` 时用户自己掌控工作区，`-A` 无妨；问题专指**被工具反复调用的提交函数**——它的调用方往往不知道工作区还躺着什么。

**证据**（commit d092eaf）：
- 复现：用探针文件 `playbook/fmprobe.md` 测 setFmField 语义，调用 curate 后 `git show --stat 5e34a66` 显示该探针被卷进了 `curate: zz-fmprobe → playbook` 提交（本应只动 bin/evo + manifest）。
- 修复：`gitCommitWithRetry` 改为接收 `[src, dest, MANIFEST]` 显式列表，5 处调用点同步传文件。
- smoke 新增 `curate 不卷入无关文件（提交边界）` 守护。
