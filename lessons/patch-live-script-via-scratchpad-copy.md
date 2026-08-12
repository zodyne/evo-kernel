---
id: patch-live-script-via-scratchpad-copy
type: lesson
status: candidate
scope: global
domain: workflow
tags: [patching, scratchpad, py_compile, diff, backup]
triggers:
  - "要原地修改一个正在使用的单文件脚本（无 git 保护的 tools/ 脚本）"
  - "对活文件做多轮试探性改动，怕改坏没有回退手段"
  - "patch 流程：副本上改 → 语法验证 → diff 审查 → 落盘 → 再验证（本条目即该流程的验证记录）"
  - "改完活文件没留 .bak，出问题想回退（失败信号）"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:06d00000-c5a0-4247-9e4a-de361d19d25e
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [bash-source-root-breaks-when-script-moved]
---

原地修补一个**不在 git 保护下**的活脚本时，用「scratchpad 副本工作流」：先 `cp` 到 scratchpad → 在副本上改 → `python3 -m py_compile <副本>` 验证 → `diff -u` 审查改动 → 落盘到活文件 → 再对活文件 `py_compile` 确认 → 保留 `.bak_<date>` 备份。本会话用该流程对 `~/graph-lab/tools/multi_model_mcp.py` 连续打了三轮补丁（709→842→861 行），每轮都有 COMPILE_OK / LIVE_SYNTAX_OK 卡口，零返工。

为什么值得走全套：活文件不在版本控制里时，唯一的安全网就是 .bak + diff 审查；`py_compile` 是落盘前后最便宜的语法闸门，能拦住"补丁本身写坏"这类低级事故。

边界：副本只是**编译和 diff 的载体，不要执行副本**——脚本若用 `$BASH_SOURCE` 推项目根，挪位置执行会静默空转，见 [[bash-source-root-breaks-when-script-moved]]。有 git 跟踪的文件该用 git 分支/stash，不必手工 .bak。
