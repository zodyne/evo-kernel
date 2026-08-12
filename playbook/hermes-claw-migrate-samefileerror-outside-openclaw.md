---
id: hermes-claw-migrate-samefileerror-outside-openclaw
type: bullet
status: validated
scope: global
domain: hermes
tags: [hermes, migration, pathlib, bug, openclaw]
triggers:
  - "hermes claw migrate 崩 SameFileError"
  - "openclaw workspace 在 ~/.openclaw 之外（如 ~/Desktop/workspace）时迁移失败"
  - "pathlib 用 / 拼接绝对路径，左操作数被丢弃"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:capture-2026-08-11-07-57-12-384-ke6c
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
---
hermes claw migrate 官方迁移器 bug：workspace 在 `~/.openclaw` 之外时必崩 SameFileError。

**为什么**：`archive_docs` 对源目录外的文件用 `relative_label` 拿到绝对路径，pathlib 的 `archive_dir / 绝对路径` 会丢弃左操作数，destination 变回源文件自己，复制即撞 SameFileError。
**修法**：`relative_label` 的 ValueError 分支里用 `p.relative_to(p.anchor)` 去掉锚点，使拼接结果落在归档目录内。
**边界**：上游 NousResearch/hermes-agent 未修，可提 issue；workspace 在 `~/.openclaw` 内时不触发。
**证据**：已在 2026-08-11 本机迁移（workspace 位于 ~/Desktop/workspace）中验证修复有效。
