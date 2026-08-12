---
id: hermes-cron-create-positionals-before-options
type: bullet
status: validated
scope: global
domain: hermes
tags: [hermes, cron, cli, argparse]
triggers:
  - "hermes cron create 报 unrecognized arguments"
  - "把 prompt 写在 hermes cron create 的选项后面"
  - "CLI 报错 usage 打的是主 parser 而不是子命令"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:capture-2026-08-11-07-57-12-634-t55q
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [hermes-cron-model-drift-fail-closed]
---
`hermes cron create` 的位置参数（schedule/prompt）必须写在所有选项之前，否则被顶层 parser 报 `unrecognized arguments`。

**为什么**：报错时 usage 打的是主 parser 而不是 cron 子命令，具迷惑性，容易误以为是选项名写错。
**验证**：位置参数前置后正常创建，输出 `Created job: <id>` / Schedule / Next run；若提示 `⚠ Gateway is not running — jobs won't fire automatically`，需 `hermes gateway install`（Linux 服务器用 `sudo hermes gateway install --system`），用 `hermes cron status` 确认。
**证据**：2026-08-11 本机创建晨报 cron 任务时复现并验证。
