---
id: 2026-09-13-pi-workflow-script-node-check-esm
type: lesson
status: validated
scope: global
domain: pi
tags: [pi, workflow, node, syntax, esm]
triggers:
  - "写或改 pi 的 workflow 脚本（export const meta 的 .js）"
  - "node --check 验 workflow 脚本报 Illegal return statement"
  - "workflow 脚本语法验证过不了但 pi 里能跑（失败信号：误判脚本坏了）"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a099a8-07d2-766c-b240-9eaed5f6ca6d
last_verified: 2026-09-13
superseded_by: null
schema_version: 1
---

**主张**：pi workflow 脚本（.js，含 `export const meta`，且允许顶层 `return`）不能直接 `node --check`——ESM 解析下顶层 return 报 `SyntaxError: Illegal return statement`；可行验证法是临时把 `export const meta` 替换为 `const meta`、把整份源码包进 async 函数后再 --check（模拟 workflow 运行时的函数上下文）。

**为什么**：workflow 运行时把脚本当函数体执行，源码里的顶层 return 在 pi 里合法，node --check 按纯 ESM 顶层规则判非法；把 --check 的报错当"脚本坏了"会误判。

**反例/边界**：`node --input-type=module -e "import …"` 直接运行适合查逻辑，但脚本引用运行时注入的变量会立刻运行时报错，别把这类错误当语法错误。

**证据**（session:01a099a8-07d2-766c-b240-9eaed5f6ca6d）：`node --check claim-audit.mjs`（原样拷贝自 ~/.pi/agent/workflows/claim-audit.js）→ `SyntaxError: Illegal return statement`（claim-audit.mjs:90 `return {`）；同一份源码替换 export + 包 async 后 → `语法 OK（按 async 上下文校验）`，并顺带完成裸 undefined 出口检查（:58/:80/:106/:172）。
