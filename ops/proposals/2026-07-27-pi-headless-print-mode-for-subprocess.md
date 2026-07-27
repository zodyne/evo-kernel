---
id: pi-headless-print-mode-for-subprocess
type: fact
status: candidate
scope: global
domain: cli-tooling
tags: [pi, pi-coding-agent, headless, subagent, subprocess, print-mode, orchestration]
triggers:
  - "想把 pi 当子进程 / 子代理执行器，从脚本或上层 harness（Claude Code workflow 等）调起"
  - "pi 默认进 TUI 交互模式，脚本里挂住或拿不到一次性输出"
  - "需要 pi 跑完即退、不落会话文件的一次性调用"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:fa7187d7-2951-4d30-a0f9-9c30f60229d4
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
# pi 可用 `pi -p -nt --no-session "<prompt>"` 做无 TUI、不落会话的一次性调用，适合被脚本/上层 harness 当子进程执行器

## 主张
pi（@earendil-works/pi-coding-agent）支持完全非交互的一次性调用：`pi -p -nt --no-session "<prompt>"`。三个开关组合的含义：`-p`（print mode，输出到 stdout 后退出）、`-nt`（no TUI，不进交互界面）、`--no-session`（不持久化会话文件）。三者合起来即"跑完即退、不挂 TUI、不留会话状态"，正是把 pi 当子进程/子代理执行器（如 Claude Code workflow 派发子任务）所需的最小调用形态。

## 为什么
若直接 `pi "<prompt>"`，默认进 TUI 交互模式，脚本/父进程会阻塞在终端 UI 上、也拿不到干净的 stdout。`-p -nt --no-session` 让 pi 退化成一个"输入 prompt → stdout 输出结果 → 退出"的纯子进程，可被任何上层 harness 用标准 stdin/stdout 管道调度。

## 证据（本会话命令 ↔ 结果，切片硬证据）
- `cd /private/tmp/claude-501/.../scratchpad && time pi -p -nt --no-session "Reply with exactly: OK"` → 输出 `OK`，计时 `0.79s user 0.12s system 15% cpu 5.720 total`——即 pi 在该模式下正确返回 `OK`、约 5.7s 端到端退出，未挂起。
- 该命令正是本会话为回答"能否用 pi 作子代理执行器"而做的探针，结果为可行（基础调用层）。

## 边界 / 反例
- 本证据只验证了"最小 headless 调用能返回正确文本、约 6s 退出"，**不**证明完整子代理编排（多轮、长任务、错误重试、并发调度、真实复杂任务的延迟与可靠性）也已就绪——那些需另测。
- 5.7s 含进程冷启动（model 冷启 / node 启动），不代表单步推理延迟；用作子代理时要把冷启动开销算进调度成本。
- `--no-session` 意味着该次调用不进 pi 的会话历史，无法事后回溯或续聊；需要可续会话的场景应去掉该开关（代价是会落会话文件）。
- 默认 provider/model 取自 `~/.pi/agent/settings.json`（本机当时 `defaultProvider=kimi-coding, defaultModel=k3`），子代理行为随该配置变化，调度方应显式锁定 model。

## 失败信号（未来命中即该想起本条）
- 从脚本/harness 调 `pi "<prompt>"` 后进程挂在 TUI、stdout 拿不到结果。
- 想把 pi 接成 Claude Code workflow / 其他编排的子代理，却不知道用哪几个开关让它非交互退出。
- 调起 pi 后发现莫名多出一堆会话文件，污染 session 目录。
