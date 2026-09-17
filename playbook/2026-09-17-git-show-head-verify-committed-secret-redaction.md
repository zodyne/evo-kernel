---
id: git-show-head-verify-committed-secret-redaction
type: lesson
status: validated
scope: global
domain: git-security
tags: [git, security, redaction, credentials, secrets]
triggers:
  - "提交含凭据/密钥的配置备份或快照到 git 前做了脱敏"
  - "想验证上次 commit 里入库的到底是脱敏版还是明文"
  - "脱敏后再读工作区文件仍是脱敏内容，但不确定 commit 对象里存的是什么"
  - "把含 secret_key/api_key 的明文文件移进 snapshots 并提交"
  - "凭据红线：确认明文没进 git 历史（失败信号：只读了工作区就下结论）"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a3f4-bbd4-763d-a251-9f1065aa3a2a
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
---

提交含凭据的配置快照前做完脱敏后，必须用 `git show HEAD:<path>` **直接读 git 对象**来验证入库的是脱敏版；读工作区文件不可靠，因为工作区可能已被再次脱敏，读它看到的是脱敏后的样子，看不到真实入库内容。

为什么：把 singbox-config.json / searxng-settings 里的 `secret_key` / `api_key` 明文脱敏后 commit，用 `git show HEAD:snapshots/20260915-194941-baseline/singbox-config.json` 从 git 对象直接读，确认输出里 password 字段与 secret_key 字段的值均为 `<REDACTED>`。

反例/边界：脱敏脚本作用在工作区文件上，commit 的却是另一个时点/另一份内容；「我读到的文件是脱敏的」不等于「commit 里存的是脱敏的」——两者必须用 `git show` 对 git 对象单独验证，否则明文可能已进历史而自以为安全。
