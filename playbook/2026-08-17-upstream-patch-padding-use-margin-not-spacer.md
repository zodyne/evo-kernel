---
id: upstream-patch-padding-use-margin-not-spacer
type: lesson
status: validated
scope: global
domain: git-workflow
tags: [patch, upstream, git-apply, 3way, react, ink, maintenance]
triggers:
  - "长期维护 upstream patch，升级后 git apply --3way 冲突"
  - "在上游子树里补空行/垫层：用 spacer 子节点还是父 Box margin"
  - "patch 行数反复变化、每次升级都要手工 rebase"
  - "想让上游子树与上游逐字节一致，只剩容器那一行差异"
created: 2026-08-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-17-09-27-06-742-7uk3
last_verified: 2026-08-17
superseded_by: null
schema_version: 1
related: [git-add-n-untracked-into-diff-patch]
---

# 主张

长期维护 upstream patch 时，要在上游子树里补空行/垫层，用**父 Box 的 `marginY`（或 `margin` 属性）**而不是插入 `<Box height={1}/>` spacer 子节点。

# 为什么

spacer 会落在**上游子树的头尾两端**，正是 `git apply --3way` 最吃上下文的位置，每次升级都可能冲突；`margin` 让子树与上游逐字节一致，只剩容器那一行差异。

# 证据

hermes-custom-ui v2.14 实测 patch 3485→3470 行，行为零变化（tsc 干净 / eslint 零 warning / vitest 158 文件 1694 过）。
