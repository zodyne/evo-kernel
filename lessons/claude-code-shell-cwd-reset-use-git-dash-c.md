---
id: claude-code-shell-cwd-reset-use-git-dash-c
type: lesson
status: deprecated
scope: global
domain: harness-config
tags: [claude-code, bash, git]
triggers:
  - "Claude Code 会话里跨多个仓库执行 bash/git 命令"
  - "上一条 cd 进别的目录，下一条命令却在原仓库执行（失败信号）"
  - "输出里出现 Shell cwd was reset to ... 提示"
  - "依赖 cwd 的相对路径命令在会话里时好时坏"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:583c96aa-69cd-41b3-926b-4f72d4d7c7f5
last_verified: 2026-07-30
superseded_by: skill:claude-code
schema_version: 1
---

Claude Code 的 Bash 工具不保证 cwd 跨命令持久：会话中出现过 `Shell cwd was reset to /Users/zodyne/Dev/ucm221`——前一条 `cd /Users/zodyne/Dev/ucm221` 后紧接着的 `git diff` 实际在别的仓库上下文执行（结果为空，险些误判"无改动"）。

对策：跨仓库操作不要依赖上一条 `cd`，每条命令自带定位——`git -C <repo> status/diff`、绝对路径读文件。cwd 被重置后相对路径命令静默跑在错的仓库，比报错更危险。
