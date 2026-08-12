---
id: report-schema-claims-need-live-ground-truth
type: bullet
status: validated
scope: global
domain: research-method
tags:
- 调研报告
- ground-truth
- 实测
- 审查纪律
- schema
triggers:
- 调研报告把 CLI --help/文档转述的输出结构当结论
- 设计文档的 jq/解析脚本依赖未实测的字段名
- 写审查报告，发现栏与缓解/建议栏都要标验证状态
- 报告里的结构/schema 类断言从没跑过真实命令
created: 2026-08-06
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: capture:capture-2026-08-06-09-15-42-579-zor4
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related:
- verify-external-references
- macos-no-timeout-command
---
调研报告把 `--help`/文档转述的结构当实测结论是高危失真：结构/schema 类断言必须跑一次真实命令取 ground truth，并标注 [实测]。

**案例**：W1 报告称 `openclaw --json` 信封含 `ok/final/costUsd`（来自 docs），实测这些字段全不存在，依赖它们的设计文档 jq 脚本全废。

**审查标签纪律**：要同时覆盖"发现"栏和"缓解/建议"栏——v2 报告只覆盖了前者，建议栏混入未验证命令，读者分不清哪条能直接照抄。

**边界/附注**：macOS 本机 `gtimeout`/`timeout` 均不存在，shell 编排器的测试门禁必须自带超时方案（不能假设 GNU coreutils 已装）。
