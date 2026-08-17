---
id: claude-hook-sessionstart-no-prompt
type: bullet
status: deprecated
scope: global
domain: harness-config
tags: [claude-code, hooks, sessionstart]
triggers:
  - "配置 Claude Code hook 注入上下文"
  - "SessionStart hook 拿不到用户输入"
  - "想在会话开始时注入记忆/经验"
created: 2026-07-23
evidence: {helpful: 2, harmful: 0}
verified_by: human
source: session:blueprint-review
last_verified: 2026-07-23
superseded_by: skill:claude-code
---
Claude Code 的 SessionStart hook 触发时用户尚未输入 prompt，stdin 里是会话元数据 JSON，**拿不到任务文本**。需要首条用户输入的场景必须用 **UserPromptSubmit** hook（stdout 进 additionalContext；注意它每次输入都触发，要去重）。
**反例**：v1 蓝图按 SessionStart 设计注入，若带进实施会导致自动注入验收莫名失败。
**边界**：实施前以官方 hooks 文档核实 stdin JSON 字段名。
