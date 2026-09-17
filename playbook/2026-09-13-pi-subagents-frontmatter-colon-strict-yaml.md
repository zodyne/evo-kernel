---
id: pi-subagents-frontmatter-colon-strict-yaml
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi-subagents, frontmatter, yaml, description, block-scalar, silent-failure]
triggers:
  - "pi-subagents 代理 .md 的 description 含 '冒号+空格' 报 Nested mappings are not allowed in compact mappings"
  - "自定义代理 .md 整文件被跳过、静默回落到内置代理（失败信号）"
  - "description 该怎么写成块标量（description: >-）"
  - "验证代理是否加载：看 stderr 有无 [pi-subagents] Skipping"
  - "pi-subagents 覆盖内置代理没生效，且没有任何报错"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-13-05-11-53-856-8yfj
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
related: []
---

# 主张

pi-subagents 代理 `.md` 的 frontmatter 是严格 YAML：description 里含「冒号+空格」的未引号标量会报 `Nested mappings are not allowed in compact mappings` 并整文件跳过（回落到内置代理，静默失去覆盖）。写成 `description: >-` 块标量。

# 验证

`pi -p --no-session --thinking off '只回复 ok'`，看 stderr 有无 `[pi-subagents] Skipping`。
