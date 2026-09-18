---
id: nvim-locate-option-toggle-via-setter-wrap-traceback
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, debug, traceback, instrumentation]
triggers:
  - "nvim 里某个选项（wrap/conceallevel 等）被反复切换，找不到是谁在改"
  - "屏幕/光标闪烁、设置来回跳，怀疑有插件在自激改 option"
  - "想定位'哪个插件/哪行代码在 set 某个 vim 选项'"
  - "只在特定文件/特定行宽下才复现的 nvim 显示 bug"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad58-5cb3-74a5-bda5-47c14fb2ba3a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---
定位「谁在反复翻某个 vim 选项」：包装 `vim.api.nvim_set_option_value`，在 wrapper 里记 `vim.uv.hrtime()` 时间戳 + 新旧值 + `debug.traceback()` 调用栈，跑一次操作后从日志的 SET 事件顺着栈定位到具体插件源码行。证据：本会话用 repro.lua/repro2.lua 包装 setter，traceback 直指 render-markdown 的 env.lua/ui.lua，统计出 8.6s 窗口内 2913 次 SET（337 writes/s）的自激翻转，据此锁定根因并修复。
反例/边界：lazy.nvim 插件里 traceback 第一帧常是 require/包装器，须往下多看几帧；`vim.schedule` 或 autocmd 异步回调里改选项时，setter 调用点是调度点而非真凶，traceback 会误导，需结合时序日志推断。
