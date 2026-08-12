---
id: git-check-ignore-before-committing-sensitive-notes
type: bullet
status: candidate
scope: global
domain: git
tags: [git, gitignore, secrets, check-ignore]
triggers:
  - "把含凭据/敏感信息的笔记文件写进 git 仓库"
  - "不确定某个文件会不会被未来的 commit 卷进库"
  - "git check-ignore 退出码的含义（exit 0=已忽略，exit 1=未忽略）"
  - "仓库根目录新增了临时/敏感文件，准备收工前"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fadd9-8a08-71ac-a7ec-763d06fbfb08
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [mask-secrets-when-reading-config, auto-script-git-add-all-sweeps-unrelated-files]
---

**主张**：敏感文件落盘 git 仓库后，用 `git check-ignore -v <file>` 验证忽略状态：exit 0 = 被 .gitignore 覆盖，exit 1 = 未忽略（存在被后续 commit 卷入库的风险），并对照 .gitignore 现有规则确认。

**证据**：会话中对写入 evo-kernel 仓库根目录的 `api-keys-pi-openclaw.md` 执行 `git check-ignore -v`，输出 `exit=1`；对照 .gitignore 仅有 ops/log 等规则，确认该文件未被忽略。

**边界**：本会话只验证到"未忽略"这一步；exit=1 后的处置（追加 .gitignore 规则或移出仓库）需另行完成并确认。check-ignore 只查 ignore 规则，不反映文件是否已被跟踪。
