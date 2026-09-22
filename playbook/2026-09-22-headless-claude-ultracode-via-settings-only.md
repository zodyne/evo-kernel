---
id: headless-claude-ultracode-via-settings-only
type: playbook
status: validated
scope: global
domain: claude-code
tags: [claude-code, ultracode, workflows, headless, effort, gateway]
triggers:
  - "想在无头 Claude Code（-p / Agent SDK）会话里开 ultracode"
  - "在 -p 提示里写了 ultracode 关键字但没生效"
  - "开了 ultracode 但 Workflow 工具仍不可用"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:inbox/capture-2026-09-20-09-50-30-335-wegs
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [claude-code-nanoradar-gateway-settings, deepseek-reasoning-effort-levels-mapping]
---

# 无头会话开 ultracode 只能靠 `--settings`，`-p` 提示里的关键字无效

**主张**：`claude -p` / Agent SDK 会话经网关 + 非 Anthropic 模型（本例 nanoradar + deepseek-v4-flash）
**能**开 ultracode，但只能靠设置：
`--settings '{"ultracode":true,"enableWorkflows":true}'`。
开启后：`init.tools` 含 `Workflow`、会话记录注入 `ultra_effort_enter` 提醒、
assistant 消息 `effort=xhigh`（而 `modelUsage` 仍只有 deepseek）。
**`-p` 提示里的 ultracode 关键字无效**；`Workflow` 还要进 `allowedTools`。

## 为什么

交互式的关键字触发通道在 `-p` 路径上不存在（无 UserPromptSubmit 那条链），
所以开关只剩设置文件。而「设置开了」与「工具可用」是两件事：`enableWorkflows` 决定工具是否注册，
`allowedTools` 决定它是自动放行还是要问。

## 证据（2026-09-20 实测，Claude Code 2.1.277）

- 开前后同一句 `pong` 的输入 token：**19.4K → 23.6K**（代价可量化）。

## 边界 / 反例

- 代价是这个量级的**一次**测量；随系统提示与工具集变化会变。
- 版本相关（2.1.277）；且经网关转发时 `modelUsage` 的模型名不反映 effort 档位。
