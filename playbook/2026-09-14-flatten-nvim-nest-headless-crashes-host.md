---
id: flatten-nvim-nest-headless-crashes-host
type: lesson
status: validated
scope: global
domain: nvim
tags: [flatten.nvim, nvim, headless, crash, nesting, terminal]
triggers:
  - "nvim 里跑 CLI agent（pi/codex 等）时 nvim 闪退"
  - "外部工具或 agent 调 nvim --headless 后宿主 nvim 会话被一并关掉（失败信号）"
  - "配置了 flatten.nvim 的 nest_if_no_args=true"
  - "guest nvim 执行 +qa! 退出时连带 host 一起退出"
  - "想给 flatten.nvim 加逃生门或自定义 should_nest 钩子"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09f1a-ce5f-74d6-aeb7-1ea49cc22f12
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: [nvim-headless-hangs-without-explicit-quit]
---

# flatten.nvim 的 nest_if_no_args=true 会把外部 nvim --headless 嵌套进 host，guest 退出连带 host 闪退

## 主张

flatten.nvim 配 `nest_if_no_args=true` 后，任何「不带文件参数」启动的 nvim 都会被嵌套进已存在的 host nvim 会话——包括外部 agent/CLI 为了体检跑的无头命令 `nvim --headless "+checkhealth" +qa`。当这个 guest 执行 `+qa!` 退出时，嵌套机制会连带把 host 一起退出，从用户视角看就是「nvim 里跑 agent 后整个 nvim 闪退」。

## 为什么

flatten.nvim 的设计是让终端里的 nvim 实例复用同一个 host（避免终端嵌套）。`nest_if_no_args=true` 把判定放宽到「只要没带文件参数就嵌套」，于是 `nvim --headless ...` 这类工具性调用也被误判成「想打开一个新窗口」，被塞进 host；guest 的退出事件被当成「该结束整个会话」传播到 host。

## 反例 / 边界

- 逃生门：host 侧配置 `should_nest` 钩子，对「headless 或带 FRESH_NVIM=1 环境变量的 guest」返回 false（不嵌套），host 就能在 guest 退出后存活。
- 仅给 guest 加 FRESH_NVIM=1 而不配 should_nest 钩子不够——实测仍闪退（实验D 初版）；必须「钩子 + 环境变量」配合。
- 根因排查入口：用户报告「打开 agent 后 nvim 闪退」，先查是不是有外部工具在跑 `nvim --headless`，再查 flatten 的 nest 配置。

## 证据

切片里的受控实验序列（pty 内起一次性 host nvim + flatten + nest_if_no_args=true）：
- 实验D（初版，仅 guest 带 FRESH_NVIM=1）：guest `+qa!` 后 host「退出 ❌ 仍会闪退」。
- 实验D（正确版，should_nest 钩子 + guest 带 FRESH_NVIM=1）：`host pid=34877  guest 执行 '+qa!' 后 host：活着 ✅`。
- 端到端复现（host=真实 nvim 配置）：`host pid=34873`，从 pi 角度跑致命命令 `nvim --headless "+checkhealth" +qa`，`guest 退出码=0  host:`（随 guest 退出）。
