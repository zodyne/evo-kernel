---
id: pi-rpc-mode-headless-drive-extension-command
type: lesson
status: validated
scope: global
domain: agent-harness
tags: [pi, rpc, extension, command, headless, goal, jsonl]
triggers:
  - "想 headless/脚本化驱动 pi 扩展注册的 slash 命令（如 /goal）"
  - "pi -p 跑扩展命令报 unavailable in print mode，需要非交互替代路径"
  - "要脚本化发 prompt 给 pi 并拿到 goal-state / 状态转移这类结构化事件"
  - "pi --mode rpc 怎么用、发什么帧、事件流长什么样"
  - "需要脱离 TUI 观察 pi 扩展命令的执行状态与轮次计数"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adec-afab-764c-a77e-517351584594
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [pi-extension-command-print-json-mode-unavailable]
---
# headless 驱动 pi 扩展 slash 命令走 `pi --mode rpc`：发 get_state/prompt 帧，读 JSONL 事件流

## 主张
`pi --mode rpc --no-session -a` 接受 stdin 上的 JSON 帧（`{"type":"get_state","id":"1"}`、
`{"type":"prompt",...}`），并把事件写成 JSONL 流；脚本发 prompt 帧即可在非交互态驱动扩展注册的
slash 命令（如 `/goal`），从事件流里拿到 `goal-state` 状态转移（active→paused）、`autoTurns`、
`tokensUsed` 等结构化进度，从而脱离 TUI 做 headless 验证。

## 为什么
print/json 模式不暴露扩展命令界面（见 related 提案），但「扩展命令无法 headless 跑」是假结论——
RPC 模式就是为此设计的管道：客户端用 JSON 帧控制会话、读回结构化事件。知道有这条路，就不会在
print 模式里反复撞墙，也不会为了验证一个扩展命令去开 TUI 人工盯屏。

## 证据（本会话命令对照）
- 自写 `rpc-drive.mjs` 发 prompt 帧后：`sending goal prompt [entry] goal-state status=active [response] prompt success=true [entry] goal-state status=active ...`
- 最终状态：`FINAL goal-state: status=paused tokensUsed=71935 autoTurns=3 iters=4 time=4.74s`——goal 命令真跑起来了，autoTurns 计数在涨。
- 无扩展报错：`pi --mode rpc --no-session -a ... → NO EXTENSION ERRORS`（对比 print 模式报 unavailable）。
- 事件流可从 JSONL 解析：`{"type":"session","version":3,"id":"...","cwd":"..."}`，entry_appended / goal-state 逐条落盘。

## 边界 / 反例
- 覆盖本机 pi 0.85.1 的 RPC 帧格式（get_state / prompt），字段名若随版本变化需照 docs/rpc.md 校准。
- RPC 模式是「长驻会话管道」，发完 prompt 要等事件流推进到目标状态，不能像 print 那样一次性拿终态。
- 只发 `get_state` 不触发任何扩展命令；真正驱动靠 `prompt` 帧，goal 状态由事件流回传。

## 失败信号（未来命中即该想起本条）
- 想脚本化跑 pi 扩展命令，却只知道 print/json 模式，结果命令不执行。
- 需要非交互观察 pi 扩展命令进度/轮次，但没意识到有 RPC 事件流可读。
- 验证扩展命令时被迫开 TUI 人工盯屏。
