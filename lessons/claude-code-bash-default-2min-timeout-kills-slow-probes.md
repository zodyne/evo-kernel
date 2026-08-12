---
id: claude-code-bash-default-2min-timeout-kills-slow-probes
type: lesson
status: candidate
scope: global
domain: harness-config
tags:
- claude-code
- bash
- timeout
triggers:
- 在 Claude Code 里用 Bash 探测慢端点（LLM API / 编译 / 渲染）
- 命令报 Exit code 143 / Command timed out after 2m 0s（失败信号）
- 慢任务被误杀，分不清是挂了还是被工具超时掐掉
- 给预期超过 2 分钟的命令没显式传 timeout 参数
created: 2026-07-30
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: session:583c96aa-69cd-41b3-926b-4f72d4d7c7f5
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related:
- kimi-api-latency-streaming-thinking
- kimi-api-latency-streaming-thinking
---

Claude Code 的 Bash 工具默认约 2 分钟超时：探测 LLM 端点的长生成请求被以 `Exit code 143 / Command timed out after 2m 0s` 掐掉——这是 harness 侧超时，不是目标服务失败，两者要分清。

会话证据：同一会话里，显式控制耗时的探测拿到真实结果（134~173s 的 RemoteProtocolError），而没设 timeout 的那次在 2m0s 被 SIGTERM，白等且拿不到诊断信息。

对策：预期 >2min 的命令显式传 timeout 参数；并在脚本内部（如 httpx）设自己的超时与计时打印，让失败原因归属清晰（harness 杀 vs 服务端断）。
