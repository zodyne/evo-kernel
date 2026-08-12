---
id: cleanup-untracked-via-trash-not-rm
type: lesson
status: candidate
scope: global
domain: git-hygiene
tags: [git, untracked, cleanup, trash, rm, reversible]
triggers:
  - "要删除不在版本控制里的文件/目录（git ls-files 返回空）"
  - "清理工作区里的生成物/遗留文件，手已经放在 rm 上"
  - "删除 untracked 文件后才发现还有用，git checkout 救不回来（失败信号）"
  - "AI/agent 自动执行清理类任务，删除动作要可回滚"
created: 2026-08-10
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019febb9-0322-7070-b2cc-57b137bdeda1
last_verified: 2026-08-10
superseded_by: null
schema_version: 1
related: [backup-untracked-file-before-edit, grep-verify-untracked-artifact-stale-before-delete]
---
# 清理 untracked 文件用 `mv ~/.Trash/` 不用 `rm`：删除动作保持可恢复

## 主张

删除不受版本控制的文件时，用 `mv <file> ~/.Trash/`（macOS）代替 `rm`：效果同样是工作区干净，但删错了能从废纸篓整体恢复。untracked 文件没有任何 git 安全网，可恢复删除是零成本的兜底——即使已经做过出处确认，确认本身也可能是错的。

## 证据

algommw 仓库清理会话（本 session）：确认 `pointcloud.csv`/`tracks.csv` 不再被生成后，执行

```
$ mv pointcloud.csv tracks.csv ~/.Trash/ && echo moved-to-trash
↳ moved-to-trash
```

两个合计约 4MB 的 CSV 被移入废纸篓而非 rm 销毁，工作区达成「干净」目标的同时保留恢复路径。

## 反例/边界

- 只适合交互式清理单量文件；批量/脚本化清理（数百个）移 Trash 会污染废纸篓，此时用「先移到仓库外临时目录 + 观察期」替代。
- 大文件（GB 级）移 Trash 不释放磁盘，目标若是腾空间需另行权衡。
