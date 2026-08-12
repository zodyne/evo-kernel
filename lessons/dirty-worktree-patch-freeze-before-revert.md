---
id: dirty-worktree-patch-freeze-before-revert
type: lesson
status: candidate
scope: global
domain: git-hygiene
tags: [git, cleanup, worktree, patch]
triggers:
  - "清理脏工作区/脏分支"
  - "git checkout -- 会丢未提交改动"
  - "还原工作区前保全"
  - "未跟踪文件和未提交修改怎么处理"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:c0a7ecbd
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---

**主张**：清理脏工作区时，**已跟踪文件的未提交修改**从未进过 git，直接还原工作区即永久丢失。正确顺序：定性每一项脏数据 → 对要保留的打 patch 并**验证可恢复**（patch 能干净 apply）→ 提交冻结（commit）→ 才动工作区还原 → 最后跑回归确认没顺手弄坏东西。

**为什么**：实测清理出 12 项脏数据，其中 2 项是 470 行未提交修改、7 项是同一未提交工作体（约 1300 行互相引用）——体量决定了不能随手 `git checkout --`。还原后跑了回归验证。

**边界**：成组的同一工作体（互相引用的报告/实验/代码）应整体归档冻结而不是拆散；去留是用户的决定，代理只保全不替决。

**证据**：2026-07-27 ucm221-pointcloud-2.0 分支清理会话，12 项脏数据分类处置、patch 验证 restorable 后冻结还原。
