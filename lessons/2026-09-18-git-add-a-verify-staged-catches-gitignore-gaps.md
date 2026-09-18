---
id: git-add-a-verify-staged-catches-gitignore-gaps
type: lesson
status: candidate
scope: global
domain: git
tags: [git, gitignore, staging, large-files]
triggers:
  - "git add -A 之后、commit 之前，想确认暂存区里有没有漏网的垃圾文件"
  - "给含大量二进制/中间产物的仓库写 .gitignore，不确定是否真的盖全了"
  - "提交后发现 .bin / .pyc / 构建产物混进了 commit（失败信号）"
  - "首次 git init 一个体积几百 MB 的目录，担心把不该入库的东西一起提交"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a8cc-ab3f-76f9-ae0a-8c02d450cbc9
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

主张：git add -A 会把 .gitignore 未覆盖的大体积二进制/.pyc 一并暂存，commit 前必须用 git diff --cached 核对暂存清单（文件数/总体积/是否漏进 .bin/.pyc），把垃圾挡在 commit 之前。

证据（session 01a0a8cc）：git init 后 git add -A，随即跑「暂存核对（提交前，关键一步）」——git diff --cached 报 78 文件 / 19984 KB，并逐项断言「是否有 .bin 漏网: 无 .bin」「是否有 .pyc 漏网: 无 .pyc」。正是这一步确认 .gitignore 写对了、232MB 数据没进索引，而非凭「写对了 .gitignore」的假设直接提交。

反例/边界：git diff --cached 只看暂存区，不含未 add 的 untracked 文件；脚本/CI 里用 git add . 自动提交时，还得防它卷进不相干文件（见 auto-script-git-add-all-sweeps-unrelated-files）。

related: [commit-reproducible-artifacts-verify-determinism, auto-script-git-add-all-sweeps-unrelated-files]
