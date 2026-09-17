---
id: pi-custom-tool-render-shell-self
type: fact
status: validated
scope: global
domain: pi-harness
tags: [pi, extension, tool-render, renderShell, tui, spacing]
triggers:
  - "给 pi 写自定义工具（只覆盖 renderCall/renderResult）时输出上下多出空白行"
  - "pi 工具块之间出现 2 行空白，想调 renderShell"
  - "ToolExecutionComponent 默认 Box(1,1) 内边距叠加外层 Spacer(1) 导致间距异常（失败信号）"
  - "想知道 pi 自定义工具的 execute 能否委托 createBashTool/createReadTool 原实现"
  - "pi 自定义工具渲染多一行前导空行，想只输出 1 行"
created: 2026-09-08
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-09-08-06-41-45-140-2y3s
last_verified: 2026-09-08
superseded_by: null
schema_version: 1
related: []
---

# 主张

pi 自定义工具渲染必须设 `renderShell: "self"`。否则 `ToolExecutionComponent` 用默认 `Box(1,1)`，会在每个工具块上下各加一行内边距，叠加外层 `Spacer(1)` 变成 2 行空白；`self` 模式下 `render()` 只输出 1 行前导空行。

# 为什么

默认壳的上下内边距来自 `ToolExecutionComponent` 的 `Box(1,1)`，而工具块外层还有 `Spacer(1)`，两者叠加即为 2 行空白。设了 `renderShell: "self"` 后由工具自己控制壳，前导只留 1 行。

# 证据

- `tool-execution.js:176-200`：`self` 模式下 `render()` 只输出 1 行前导空行。

# 附：execute 可委托原实现

自定义工具的 `execute` 可以委托 `createBashTool()` / `createReadTool()` 等原实现，只覆盖 `renderCall` / `renderResult`。
