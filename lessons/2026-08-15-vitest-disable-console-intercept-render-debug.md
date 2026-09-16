---
id: vitest-disable-console-intercept-render-debug
type: playbook
status: candidate
scope: global
domain: hermes-tui
tags: [vitest, testing, debugging, console, hermes, tui]
triggers:
  - "调试 Hermes TUI 测试，想在测试里 console.log 打印渲染结果/中间态"
  - "vitest 测试明明在跑，grep 不到 console.log / debug 输出（失败信号：像没执行）"
  - "跑 npx vitest run 单个测试想肉眼确认组件输出"
created: 2026-08-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:4659d364-dabe-409a-b11c-258b78db277c
last_verified: 2026-08-15
superseded_by: null
schema_version: 1
related: []
---

主张：调试 Hermes TUI 测试里的渲染输出时，给 vitest 加 `--disable-console-intercept`，测试内 `console.log` 才会穿透到终端 stdout——否则 vitest 默认拦截 console，`grep` 不到任何输出。

证据：不带 flag `npx vitest run scratchBanner.euly.test.tsx 2>&1 | grep BANNER-OUTPUT` 输出为空（被拦截）；带 flag 同命令加 `--disable-console-intercept` 输出 `BANNER-OUTPUT: ["","⚕ Nous Research · Messenger of the Digital Gods",...]`。同一测试文件、唯一差异是 flag，证明拦截是可关的默认行为。

为什么：vitest 默认 intercept console 并把输出收进 reporter（静默），不写 stdout；用 `grep` 抓 debug 输出时看起来像「没执行/没打印」，误判方向。关掉拦截后 console 直通终端。

边界：`--disable-console-intercept` 只影响 console 输出的可见性，不影响测试断言本身；console 会污染测试输出，只在调试时临时加，别留在最终脚本里。
