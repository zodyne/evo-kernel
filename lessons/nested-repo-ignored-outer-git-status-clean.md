---
id: nested-repo-ignored-outer-git-status-clean
type: lesson
status: candidate
scope: global
domain: git
tags: [git, nested-repo, gitignore, check-ignore, git-diff]
triggers:
  - "改了文件但 git status 报 working tree clean、git diff 空输出"
  - "git diff/status 对某个子目录完全静默，但文件明明刚保存过（失败信号）"
  - "在外层仓库对嵌套 git 仓库（内含 .git）里的文件做 diff/提交，什么都看不到"
  - "自动化脚本在外层仓库跑 git status 判断有无改动，漏掉嵌套仓库的变更"
  - "排查『文件确实改了、git 却像没看见』类问题"
created: 2026-08-02
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:7c4809cc-6484-46a8-ad6b-dc591541577a
last_verified: 2026-08-02
superseded_by: null
schema_version: 1
related: [git-check-ignore-before-committing-sensitive-notes, claude-code-shell-cwd-reset-use-git-dash-c]
---
# 外层 git status 全干净但文件明明改了：先查是否是被外层 .gitignore 忽略的嵌套 git 仓库

## 主张

改过的文件在外层仓库 `git status` 全干净、`git diff` 空输出时，不要怀疑编辑器/构建没生效——先怀疑该路径位于**被外层 `.gitignore` 整个忽略的嵌套 git 仓库**里。诊断两步：`git check-ignore -v <path>` 看命中哪条 ignore 规则；`ls <dir>/.git` 确认它是独立仓库。真实的 diff/提交必须进内层仓库（`git -C <内层路径>`）操作，外层对该路径永远静默。

## 证据

会话中改完 `libucm221/src/signalProcess/tcm893/signalProcessing.tcm893.c` 等文件后：

- 外层 `git diff -- <path>`（两种相对路径写法）与 `git status --short` 全部空输出；`git status` 报 "On branch feat/faf-embedded-port nothing to commit, working tree clean"。
- `git check-ignore -v libucm221/.../signalProcessing.tcm893.c` → 命中 `.gitignore:20:/libucm221/`；`ls libucm221/.git` 确认是嵌套仓库。
- 进内层后 `git diff -- src/examples/faf_offline/main.c` 立刻出真实 diff；后续全程改用 `git -C .../libucm221 status --short`，正常显示 ` M` 改动。

## 边界

- 外层仓库用 `git add` 也救不了被 ignore 的嵌套路径（除非 `-f`，且把嵌套仓库加进外层通常是错的）。
- 与 cwd 坑叠加时更迷惑：cd 进内层后路径基准变了，建议一律 `git -C <绝对路径>`（见 related）。
- `git check-ignore` 退出码 0=已忽略、1=未忽略；命中行会给出 .gitignore 文件与行号。
