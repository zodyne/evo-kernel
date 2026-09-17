---
id: pi-print-mode-waits-on-non-tty-stdin
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, print-mode, stdin, tty, headless, hang]
triggers:
  - "pi -p 非交互模式看起来卡死，无网络连接、无子进程、事件循环空转"
  - "stdin 不是 TTY 且不会 EOF（如 Claude Code Bash 工具的 unix socket stdin）时 pi -p 一直等 stdin"
  - "脚本调用 pi -p 挂 5–8 分钟不返回（失败信号）"
  - "无人值守调用 pi -p 需要显式关掉 stdin"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-13-15-33-016-qorr
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: []
---

# pi -p 在 stdin 不是 TTY 且不 EOF 的场景会一直等 stdin，用 < /dev/null 关掉

## 主张

`pi -p` 非交互模式在 stdin 不是 TTY 且不会 EOF 的场景（如 Claude Code Bash 工具的 unix socket stdin）会一直等 stdin，看起来像卡死（无网络连接、无子进程、事件循环空转）；用 `< /dev/null` 显式关掉 stdin 即可。

## 证据

2026-09-14 实测两次各挂 5–8 分钟。
