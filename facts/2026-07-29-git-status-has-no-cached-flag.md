---
id: git-status-has-no-cached-flag
type: lesson
status: validated
scope: global
domain: git
tags: [git, staging-area, cli-flags, exit-129]
triggers:
  - "git add 之后、commit 之前想核对暂存区里到底 staged 了哪些文件"
  - "在命令链/脚本里写 git status --cached 验证刚才的 add 结果"
  - "git 报 error: unknown option `cached' 且 exit code 129"
  - "想确认 git add -- <paths> 是否按预期暂存了全部目标文件"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:dc63fb24-b5f6-455e-87c6-6bfc029de1eb
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [git-add-untracked-source-path-aborts-staging]
---

`git status` **没有 `--cached` 选项**：`git status --short --cached` 直接 `exit 129` + `error: unknown option 'cached'`。要查看暂存区内容，用 `git diff --cached`（`--stat` / `--name-only`，或别名 `--staged`）。

硬证据（evo-kernel 仓库，提交手册改动前核对暂存区）：

```
$ git add -- docs/user-manual.tex docs/user-manual.pdf && git status --short --cached
✗ Exit code 129  error: unknown option `cached'
$ git diff --cached --stat
 docs/user-manual.pdf | Bin 339864 -> 402590 bytes
 docs/user-manual.tex | 215 +++++...
```

注意连带坑：因为 `&&` 链中 `git status` exit 129，其后命令不会执行——若把它放在 `git add && git status --cached && git commit` 这种链里，commit 会被静默跳过，现象类似"add 了但没提交"。

分工记忆：`git status` 只看工作区相对暂存区的状态（含 untracked）；看"已暂存的改动内容"一律走 `git diff --cached`。
