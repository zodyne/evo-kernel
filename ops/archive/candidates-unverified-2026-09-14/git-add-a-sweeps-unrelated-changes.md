---
id: git-add-a-sweeps-unrelated-changes
type: lesson
status: candidate
scope: global
domain: git-hygiene
tags: [git, commit-hygiene, audit-trail, automation]
triggers:
  - "自动化脚本里 git add -A"
  - "提交混入无关文件"
  - "git 历史当审计线索"
  - "curate 提交裹进脏文件"
created: 2026-07-24
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:ebd9ff4c
last_verified: 2026-07-24
superseded_by: null
schema_version: 1
---

**主张**：把 git 历史当审计线索的系统（每条提交对应一次操作），自动化提交禁止 `git add -A`——worktree 里任何无关脏文件都会被裹进一条写着 `curate: <id>` 语义的提交里，直接污染审计链。应按显式路径 add。

**为什么**：实测时刻 worktree 就有 `M CONVERGENCE.md`、`M inbox/session-refs.md` 未提交，下一次任何人跑 curate 这两个无关文件就会进 `curate:` 提交；而该系统的护城河（git-as-audit-trail）正建立在提交语义纯净上。双 harness 并发 session 时间重叠是既成事实，脏 worktree 是常态而非例外。

**边界**：交互式人工提交例外（人会看 `git status`）；自动化路径一律 `git add <显式路径>`，提交前断言 `git status --porcelain` 无意外文件。

**证据**：2026-07-24 evo-kernel blueprint-v3 评审会话，`bin/evo:204` 提交实现 + 现场脏 worktree 实测。
