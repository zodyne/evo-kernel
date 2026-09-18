---
id: multi-repo-status-script-distinguish-uncloned-vs-clean
type: lesson
status: candidate
scope: global
domain: git
tags: [git, multi-repo, scripting, status]
triggers:
  - "写一个遍历多个子仓库汇报状态的脚本（status.sh / 批量 git status）"
  - "聚合仓库/多模块工作区，脚本对还没 clone 的模块报「全部干净」（失败信号）"
  - "用脚本汇总各子仓库的 branch/commit/dirty 状态给用户看"
  - "用户问『统一管理多个独立 git 仓库』怎么做"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a8cc-ab3f-76f9-ae0a-8c02d450cbc9
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

主张：跨多个子仓库汇报状态的脚本，必须显式区分「模块未克隆」和「模块干净」两种状态，否则在聚合仓库刚 clone 出来、模块还没拉时，会误导性地报「全部干净」。

证据（session 01a0a8cc）：ant_design 采用「聚合仓库（只装 README 索引 + modules.txt + scripts）+ 每模块独立 git 仓库」统一管理多个仿真模块。scripts/status.sh 在聚合仓库单独克隆（模块未拉）场景下，三行都报「全部干净」，属于误导；修复 commit 4c1d919 "fix(status.sh): 模块未拉取时不再报「全部干净」"，修后对模块未拉取场景正确标注。

反例/边界：与嵌套 git 仓库（子目录内含 .git）导致外层 git status 静默不同（见 nested-repo-ignored-outer-git-status-clean），这里是自定义状态脚本自身没枚举「未克隆」状态，属脚本逻辑缺陷而非 git 行为。

related: [nested-repo-ignored-outer-git-status-clean]
