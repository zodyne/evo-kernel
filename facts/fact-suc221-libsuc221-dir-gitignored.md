---
id: fact-suc221-libsuc221-dir-gitignored
type: fact
status: candidate
scope: project:suc221
domain: git
tags: [suc221, gitignore, libsuc221, faf-offline, version-control-blindspot]
triggers:
  - "在 suc221-pointcloud-2.0 仓库的 libsuc221/ 下写代码或报告"
  - "git status / git diff 看不到 libsuc221 下刚改的文件（失败信号）"
  - "想给 faf_offline 的脚本/报告做 git 提交或备份"
  - "奇怪为什么 git ls-files libsuc221/ 返回空"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:eaa269a8-34b2-4abf-a08f-1dd23a6ff138
last_verified: 2026-08-03
superseded_by: null
schema_version: 1
related: [backup-untracked-file-before-edit]
---
# suc221-pointcloud-2.0 仓库：整个 libsuc221/ 被 .gitignore 忽略，内部产出不受版本控制

## 事实

仓库根 `.gitignore` 第 20 行有 `/libsuc221/`，整个 libsuc221/ 目录（含 `src/examples/faf_offline/` 下的全部分析脚本、报告源文件、产物）对 git 完全不可见：`git status`/`git diff` 不显示，`git ls-files` 返回空，文件丢失后无法用 git 恢复。

## 证据

- `git check-ignore -v libsuc221/src/examples/faf_offline/progress_plot.py` → `.gitignore:20:/libsuc221/  libsuc221/src/examples/faf_offline/progress_plot.py`（exit 0，确认被忽略）。
- `git ls-files libsuc221/src/examples/faf_offline/ | head -3` 无输出，tracked count = 0。
- 同会话 `git status --short -- libsuc221/` 与 `git diff --stat -- .../gt_report.tex` 均无输出，与忽略一致。

## 影响

在 faf_offline 下做的任何工作（如 progress_plot.py / progress_report.tex）默认不进版本控制；需要留存时得显式 `git add -f`、移出忽略规则，或自行备份。自动化提交脚本若对这里的文件 `git add`，会因 pathspec 无匹配而 fatal。
