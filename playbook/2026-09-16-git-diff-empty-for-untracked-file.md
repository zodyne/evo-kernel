---
id: git-diff-empty-for-untracked-file
type: lesson
status: validated
scope: global
domain: git
tags: [untracked, git-diff, ls-files, diagnostics]
triggers:
  - "改了文件但 git diff --stat 返回空，怀疑改动丢了或没保存"
  - "git diff 看不到刚编辑的文件，想确认它是否真的被 git 跟踪"
  - "git ls-files --error-unmatch <path> 报 did not match any file(s) known to git"
  - "多 agent 并行编辑同一仓库，文件写在磁盘上却从未被 git add 提交过"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a889-98f7-7719-ba82-3209d6a06db1
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [nested-repo-ignored-outer-git-status-clean, backup-untracked-file-before-edit, git-add-untracked-source-path-aborts-staging]
---

git diff --stat 对从未 git add 的未跟踪文件静默返回空，不能据此判断"没改动"；先用 `git ls-files --error-unmatch <path>` 判定文件是否已被 git 跟踪（未跟踪时 exit≠0 并报 "did not match any file(s) known to git"）。

SPC865 工作台改造中，agent 改了 `spc865/ui/workbench.py` 与 `tests/python/test_ui_smoke.py` 后想确认改动，`git diff --stat <两文件>` 输出空（✗），接着 `git ls-files --error-unmatch <两文件>` 报 `error: pathspec 'spc865/ui/workbench.py' did not match any file(s) known to git` —— 说明这两个文件从未被 git add 纳入跟踪，git diff 根本看不见它们。

反例/边界：与"嵌套仓库导致 git diff 空"（文件其实在 inner .git 里）和"gitignore 导致 diff 空"是同一症状（git diff/status 静默空）的三种不同根因，排查时要逐个排除，不能看到空输出就认定"改动丢失"。`ls-files --error-unmatch` 对被 .gitignore 排除的文件同样返回"未跟踪"，无法区分"从未 add"与"被 ignore"，还需再核对 .gitignore。
