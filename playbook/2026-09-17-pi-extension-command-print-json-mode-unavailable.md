---
id: pi-extension-command-print-json-mode-unavailable
type: lesson
status: validated
scope: global
domain: agent-harness
tags: [pi, extension, command, print-mode, json-mode, slash-command, goal]
triggers:
  - "给 pi 写扩展注册了 slash 命令，pi -p 跑却报 unavailable in print mode"
  - "pi -p 或 pi --mode json 下扩展命令静默不执行、工具没被调用（失败信号）"
  - "想 headless/脚本化跑一个 pi 扩展命令，结果命令根本没生效"
  - "pi 扩展命令只在 TUI 交互里出现，脚本/print 模式拿不到"
  - "排查 pi 扩展注册的命令为什么在非交互模式不工作"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adec-afab-764c-a77e-517351584594
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [pi-subagent-tool-silent-failure-pitfalls, pi-rpc-mode-headless-drive-extension-command]
---
# pi 扩展注册的 slash 命令在 print / json 模式不可用——只有 TUI/RPC 才暴露扩展命令界面

## 主张
pi 扩展通过 `pi.command()` 注册的 slash 命令（如 `/goal`）只在交互态（TUI）与 RPC 模式可用；
`pi -p`（print）与 `pi --mode json` 下扩展命令**不会被执行**：要么扩展自身抛
`Extension error (command:goal): /goal status is unavailable in print mode because Pi does not
expose an extension-command...`，要么被静默跳过（命令没跑、目标产物没生成，退出码还是 0）。

## 为什么
「print 模式就是非交互批处理」的直觉会让人用 `pi -p "/goal ..."` 去 headless 跑扩展命令，结果
报错或静默失败——根因是 pi 核心只在 TUI/RPC 里暴露 extension-command 分发，print/json 是单发模式，
不加载扩展命令界面。想 headless 驱动扩展命令，得换 RPC 模式（见 related 提案），而不是在 print
模式里反复试。

## 证据（本会话命令对照）
- `pi -p "/goal"` → `Extension error (command:goal): /goal status is unavailable in print mode because Pi does not expose an extension-command...`
- `pi -p -ne -e .../pi-goal/dist/index.ts "/goal ... Create hello.txt"` → `✗ EXIT=0` 但 `cat: /tmp/goal-smoke/hello.txt: No such file`（显式 `-e` 加载扩展也救不了，命令静默没跑）
- `pi --mode json -ne -e .../pi-goal/dist/index.ts "/goal ..."` → 同样静默：EXIT=0，事件流只有 `{"session":1,"entry_appended":2,"agent_start":1}`，无 goal-state、hello.txt 不存在
- 扩展源码自带护栏：`140: if (ctx.mode === "print" || ctx.mode === "json") throw new Error(safeMessage);`

## 边界 / 反例
- 覆盖本机 pi 0.85.1 的行为。护栏是 goal 扩展自己写的，但「print/json 不暴露 extension-command」是
  pi 核心的机制性限制，与具体扩展无关。
- 若某扩展不注册 slash 命令、只挂 `pi.on(...)` 生命周期钩子，则不在此列——钩子在 print 模式仍会触发。
- 报错 vs 静默取决于调用形态：不带 `-e` 时由扩展护栏抛 unavailable；带 `-e` 显式加载扩展时反而**静默**
  （EXIT=0、无产物、无报错），比报错更隐蔽。

## 失败信号（未来命中即该想起本条）
- `pi -p` / `pi --mode json` 跑一个扩展 slash 命令，报 unavailable in print mode。
- 脚本化跑扩展命令，退出码 0 但目标产物/副作用根本没出现。
- 想 headless 跑 pi 扩展命令却只在 print 模式里兜圈子。
