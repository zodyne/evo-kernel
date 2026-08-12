---
id: claude-code-bash-timeout-backgrounded-not-failed
type: lesson
status: candidate
scope: global
domain: harness-config
tags: [claude-code, bash-tool, timeout, background-task, polling]
triggers:
  - "Claude Code 里跑 pip install / 构建等慢命令，报 moved to the background"
  - "命令提示 Command did not complete within its 120s timeout（失败信号：以为失败准备重跑）"
  - "后台任务输出文件长时间 0 字节，不确定是还在跑还是死了"
  - "想重跑一个被转后台的 pip/包管理命令之前"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:9df36dfc-790a-4022-b8d8-620e0ced67ea
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [claude-code-bash-default-2min-timeout-kills-slow-probes, claude-code-sleep-blocked-poll-output]
---

**主张**：Claude Code 的 Bash 命令超时不等于失败——慢命令会被**转后台继续跑**，提示 `Command did not complete within its 120s timeout and was moved to the background (ID: xxx)`，输出写入 `/private/tmp/claude-501/<项目路径>/<session_id>/tasks/<ID>.output`。此时输出文件可能长时间 0 字节（pip 带 `-q` 或输出缓冲），**不要误判失败重跑**（pip 重跑会重复/冲突）；正确做法是轮询该 output 文件，并用终态命令（如 `pip show <pkg>`）验证结果是否已落地。

**证据（切片硬证据）**：
- `$ python3 -m venv .venv && pip install ...` → `Command did not complete within its 120s timeout and was moved to the background (ID: b076ywqm0). Output is being writte...`。
- 立即轮询：`$ wc -l /private/tmp/claude-501/-Users-zodyne-Desktop-workflow/9df36dfc-.../tasks/b076ywqm0.output` → `0`（还在跑，无输出）。
- 稍后终态验证：`$ pip show mcp httpx` → `Name: mcp Version: 2.0.0 / Name: httpx Version: 0.28.1`——转后台的安装实际已成功。

**边界**：与 `claude-code-bash-default-2min-timeout-kills-slow-probes` 描述的行为（Exit code 143 被杀）相反——可能是 harness 版本或命令类型的差异；两条都按各自切片现象如实记录，遇到时以实际提示文案为准：看到 `moved to the background` 按本条处理，看到 `Exit code 143 / timed out` 按那条处理。`sleep` 紧跟轮询命令可能被 harness 拦截（见 `claude-code-sleep-blocked-poll-output`），轮询宜分次单发。
