---
id: mask-secrets-when-reading-config
type: bullet
status: candidate
scope: global
domain: secrets-handling
tags: [api-key, masking, security, session-log]
triggers:
  - "要在会话里查看含 API key / token 的配置文件"
  - "想把凭据信息整理进笔记或文档"
  - "直接 cat auth.json / openclaw.json / .env 之前（失败信号：明文 key 进入会话 transcript 与日志）"
  - "写收集凭据的自动化脚本，输出要落盘"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fadd9-8a08-71ac-a7ec-763d06fbfb08
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [git-check-ignore-before-committing-sensitive-notes]
---

**主张**：读取/转录含密钥的配置文件时用 python 打码输出（保留可辨识前缀如 `sk-kimi-` + 后缀 4 位，中间省略），不要直接 `cat` 全文——明文 key 一旦进入会话 transcript 就持久留在日志里。确认文件不含密钥（如 pi 的 models-store.json）后才可直接 cat。

**证据**：会话中两次用 python mask 函数读 `~/.pi/agent/auth.json` 与 `~/.openclaw/openclaw.json`，输出仅呈 `sk-kimi-...gr5P`、`7c1db7...` 形式，全程无明文 key 落盘；同会话对不含密钥的 models-store.json 则直接 cat。

**边界**：打码只降险不免泄——打码后的笔记若写进 git 仓库仍可能被提交，需配合 `git check-ignore` 验证（见 related）。
