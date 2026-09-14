---
id: claude-auto-mode-classifier-transient-deny
type: lesson
status: deprecated
scope: global
domain: harness-config
tags: [claude-code, auto-mode, classifier, transient-error]
triggers:
  - "Claude Code auto 模式下 bash 命令被拒：Stage 2 classifier error"
  - "提示 claude-sonnet 暂时不可用，auto mode 无法判定 Bash 安全性"
  - "同一条命令刚才能跑现在被 classifier 拒（失败信号）"
  - "命令被拒后想改写命令绕过，先判断是不是瞬时故障"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:0fe7c2be-cdd2-41a5-be17-e2cd31fe1740
last_verified: 2026-07-29
superseded_by: skill:claude-code
schema_version: 1
related: [evo-distill-transient-connection-error-retry]
---

**主张**：Claude Code auto 模式的权限分类器会瞬时故障（`Stage 2 classifier error`、`claude-sonnet-5 is temporarily unavailable, so auto mode cannot determine the safety of Bash right now`），此时命令被拒与命令内容无关——稍等重试即可，不要误读成"命令太危险"而去改写命令或加白名单。

**证据**：会话中同一类 `ZHIPU_API_KEY=... python -c ...` 测试命令，一次被 classifier 以 `Stage 2 classifier error` 拒绝、另一次因 sonnet 暂不可用被阻塞（提示 `Wait briefly`），未改动命令本身，稍后重跑同类命令正常执行到底。

**边界**：与"内容性拒绝"（读 `auth.json` 这类敏感文件被拒且理由明确）区分：瞬时故障的措辞含 temporarily / classifier error / Wait briefly；内容性拒绝重试多少次都一样。
