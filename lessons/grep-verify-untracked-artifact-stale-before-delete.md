---
id: grep-verify-untracked-artifact-stale-before-delete
type: lesson
status: candidate
scope: global
domain: git-hygiene
tags: [git, untracked, cleanup, generated-artifacts, grep, provenance]
triggers:
  - "git status 出现 untracked 的大文件/结果文件，想清理工作区"
  - "删除一个看起来是中间产物/导出结果（CSV/日志/点云）的文件之前"
  - "不确定某个生成物文件还是否被当前代码生成，想直接删（失败信号：删完发现下游还要用）"
  - "清理仓库根目录里历史遗留的数据文件"
created: 2026-08-10
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019febb9-0322-7070-b2cc-57b137bdeda1
last_verified: 2026-08-10
superseded_by: null
schema_version: 1
related: [backup-untracked-file-before-edit, ucm221-tracker-macros-in-ucm221-track-repo]
---
# 删除 untracked 生成物前，先 grep 代码库确认它不再被生成

## 主张

清理工作区里 untracked 的数据/结果文件前，用 `grep -rn "<文件名>" --include=*.py --include=*.c ...` 在代码库里查它的出处：命中注释/代码说明「不再产出」才可删；同时用 `git log --all -- <path>` 确认无历史。untracked 文件不受 git 保护，删错无法 `git checkout` 恢复，出处确认是删除的前置条件。

## 证据

algommw 仓库清理会话（本 session）：

- `git log --oneline --all -- _workspace/ pointcloud.csv tracks.csv` 对两个 CSV 返回空（无任何历史，纯本地产物）；
- `grep -rn "pointcloud\.csv\|tracks\.csv" ...` 命中 `./python/track_bench/run_bench.py:322: # D3 决定:不再产 pointcloud.csv/tracks.csv 中间文件(进程内驱动,无 CSV 往返)`——代码注释明确证实这两个文件（3.5MB / 514KB）是旧管线的中间产物，当前代码不再生成；
- 两项确认之后才执行删除，工作区最终干净。

## 反例/边界

- grep 全空 ≠ 文件没有出处：宏/拼接路径/生成脚本可能搜不到字面文件名（见 `ucm221-tracker-macros-in-ucm221-track-repo` 的教训），全空时要换概念词再搜或降级为移 Trash 观察。
- 本条的确认强度来自「命中明确的决策注释」；只有沉默证据（搜不到引用）时结论要降一档。
