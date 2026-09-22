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
verified_by: human
source: capture:inbox/capture-2026-09-20-09-50-30-335-wegs
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [claude-code-nanoradar-gateway-settings, deepseek-reasoning-effort-levels-mapping]
---

# 无头会话开 ultracode 只能靠 `--settings`，`-p` 提示里的关键字无效

**主张**：2026-09-20 实测（Claude Code 2.1.277，经 nanoradar 网关 + deepseek-v4-flash）：
`claude -p` 会话**能**开 ultracode，但只能靠设置——
`--settings '{"ultracode":true,"enableWorkflows":true}'`。
开启后：`init.tools` 含 `Workflow`、会话记录注入 `ultra_effort_enter` 提醒、
assistant 消息 `effort=xhigh`（而 `modelUsage` 仍只有 deepseek）。
**`-p` 提示里的 ultracode 关键字无效**；`Workflow` 还要进 `allowedTools`。

## 证据（2026-09-20 实测，Claude Code 2.1.277）

- 开前后同一句 `pong` 的输入 token：**19.4K → 23.6K**。

证据等级：`verified_by: human` —— 来源是会话内的 prose 摘要（`capture:…`），无命令转录。
**未经本机复核** —— `command` 档要求命令级可复现证据，本条没有。

## 边界 / 反例

- **配置组合只有一组**：nanoradar 网关 + deepseek-v4-flash。换网关、换模型、或直连厂商时行为未测
  —— 尤其不要把它读成「非 Anthropic 模型都能开」。
- 版本相关（2.1.277）。
- capture 只观察到「设置里 `enableWorkflows` 与 `allowedTools` 都要写」；这两个字段**各自负责什么**
  （谁决定工具注册、谁决定放行）本条不作断言——那是推的，没有观测。
- 代价（19.4K → 23.6K）是该次的一句 `pong` 的测量；换系统提示/工具集会变。
