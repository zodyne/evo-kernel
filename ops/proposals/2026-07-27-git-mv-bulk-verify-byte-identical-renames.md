---
id: 2026-07-27-git-mv-bulk-verify-byte-identical-renames
type: playbook
status: candidate
scope: global
domain: git
tags: [git, git-mv, refactor, rename, relocation, verification, archive]
triggers:
- 用 git mv 批量搬迁/重构大量文件后准备提交
- 大规模目录重组（archive/freeze、模块迁移、monorepo 整理）后想确认没夹带内容改动
- git status 一堆 R (rename) 但不确定是不是纯移动
- 重构后怀疑某个 sed / 编辑器 / 格式化顺手改了被搬迁文件的内容
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:9c7257e9-4890-48f8-b144-4f90a46031e3
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---

# 批量 git mv 之后、提交之前，验证所有 rename 都是 100% 字节一致

用 `git mv` 批量搬迁大量文件（目录重组、archive 冻结、模块迁移）后，提交前跑一条检查确认所有暂存 rename 都是纯移动、没有夹带内容改动：

```
git diff --cached -M --summary | grep rename | grep -v '(100%)'
```

**输出为空 = 每个 rename 都被 git 判定为 100% 字节一致**（纯移动）。若有输出，说明某个"rename"其实内容也变了（相似度 <100%），或干脆被记成了 delete+add——这正是要抓的"静默内容变异"。

## 为什么

`-M` 让 git 对暂存区做重命名检测并附带相似度百分比。批量搬迁时容易夹带意外改动：一个过宽的 `sed`、编辑器自动格式化、或手滑改了被搬迁文件，都会让本该 100% 一致的 rename 掉到 <100%，甚至退化成 D+A。`git status` 只显示 `R`，不一眼暴露相似度；肉眼看 diff 又会被海量 rename 淹没。这条管道只留下"不是纯移动"的行，把异常过滤到眼前。本会话把研究期约 40 个文件整体 `git mv` 进 `archive/research-phase/`，跑此检查得 `(none above = all byte-identical)`，确认无夹带改动后才提交。

## 边界

- 100% 一致只证明"内容没变"，不证明"搬对了地方"——目标路径仍需人核对。
- 想连同"被记成 D+A 但本该是 rename"的也抓出来，把 `grep -v '(100%)'` 去掉、或单独看 `git diff --cached --summary` 里的 delete/add 对。
- 文件本身就是该改内容的（迁移+重写），这条检查不适用——它只守护"本该纯移动"的场景。
