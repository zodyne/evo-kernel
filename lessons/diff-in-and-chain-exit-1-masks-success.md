---
id: diff-in-and-chain-exit-1-masks-success
type: lesson
status: candidate
scope: global
domain: shell
tags: [bash, diff, exit-code, sed, 改动验证]
triggers:
  - "用 `编辑命令 && diff 旧文件 新文件` 一条链验证改动是否生效"
  - "命令链报 Exit code 1，但输出里 diff 明明显示了预期的改动（失败信号）"
  - "改完文件想确认替换生效，把 diff 串在 && 后面"
  - "harness/脚本把整条命令的退出码当成败判据"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:0a908942-190f-4fef-b7db-437423af1169
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [patch-live-script-via-scratchpad-copy, sed-delimiter-collision-use-python-pathlib]
---

`diff` 的语义是"有差异返回 1"——而验证改动生效时**差异正是成功标志**。把 diff 串在 `&&` 链里（如 `sed -i.bak 's/a/b/' f && diff f f.bak`），改动越成功整条命令越报 Exit code 1，harness 会把一次成功的编辑渲染成 ✗ 失败。

会话证据：`sed -i.bak 's/httpx.AsyncClient(timeout=300.0)/httpx.AsyncClient(timeout=_DEFAULT_TIMEOUT)/' tools/multi_model_mcp.py && diff ...` 输出 `✗ Exit code 1`，但同时 diff 输出 `736c736 < ... > ...` 表明替换已生效——退出码来自 diff，不是 sed 失败。

做法：验证改动看 diff 的**输出内容**而非退出码；命令链里给 diff 补 `|| true`，或拆开两条命令分别看结果。
