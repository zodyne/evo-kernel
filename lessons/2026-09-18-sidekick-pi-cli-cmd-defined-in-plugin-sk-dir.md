---
id: sidekick-pi-cli-cmd-defined-in-plugin-sk-dir
type: fact
status: candidate
scope: global
domain: nvim
tags: [nvim, sidekick, pi, lazy-nvim, config-attribution]
triggers:
  - "看到 sidekick 配置里出现 cmd = { \"pi\" } / is_proc / url，想确认这是谁的配置"
  - "用户 nvim 配置里只写了 env，却要解释 sidekick 调起 pi 的完整命令行"
  - "把插件自带的 CLI 默认值当成用户配置写进报告或结论（失败信号：出处张冠李戴）"
  - "要改 sidekick 调起 pi 的方式，先找 cmd 定义在哪个文件"
  - "复核 nvim 插件类报告里的『用户配置里写了 X』断言"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ad-67d6-725c-a75a-f9894a03787a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [nvim-terminal-tmux-env-poisons-osc52-passthrough]
---

# sidekick.nvim 的 pi CLI 定义（`cmd = { "pi" }`）在插件自带的 `sk/cli/pi.lua`，不在用户 nvim 配置里

**主张**：sidekick.nvim 里"用什么命令调起 pi"的定义位于**插件目录自身** `/Users/zodyne/.local/share/nvim/lazy/sidekick.nvim/sk/cli/pi.lua`（含 `cmd = { "pi" }`、`is_proc = "\\<pi\\>"`、`url` 等字段，`return { ... }` 一份 sidekick.cli.Config）；用户的 nvim 配置（`config/nvim/lua/plugins/sidekick.lua`、`lua/configs/pi.lua`）里**没有 `cmd` 字段**，只提供 `env = {...}` 之类的覆盖。把 `cmd = { "pi" }` 归因为"用户配置"是错的。

**证据（本会话命令对照）**：
- `cat -n /Users/zodyne/.local/share/nvim/lazy/sidekick.nvim/sk/cli/pi.lua` →
  `1  ---@type sidekick.cli.Config` / `2  return {` / `3  cmd = { "pi" },` / `4  is_proc = "\\<pi\\>",` / `5  url…`（切片可见前几行，定义就在插件侧这个文件里）；
- 对抗式复核的结论同时指出：`cmd = { "pi" }` 不在用户配置里，用户配置只有 `env = {...}`——即这是一处"出处张冠李戴"（引文真实、归属错误）。
- 归属核对方法：用户侧文件在 `lazy.nvim` 装出来的插件目录 `/Users/zodyne/.local/share/nvim/lazy/<plugin>/` 之外，同一字段名要先在插件目录里 `rg` 一遍再归因。

**边界 / 易混**：
- 三处配置要分清：①插件自带默认（`sk/cli/pi.lua`）②用户插件配置（`lua/plugins/sidekick.lua` 的 setup/`lua/configs/pi.lua`）③pi 自身的 `~/.pi/agent/settings.json`；本会话核到 `jq -r '.tuiMode' ~/.pi/agent/settings.json` → `fullscreen`，用户配置里的注释也正是"TUI 模式已在 settings.json 全局设定、这里不再重复传 `--tui-mode`"，不要把这类运行时行为算到插件头上；
- 插件升级会覆盖 `sk/cli/pi.lua`，要长期改变的参数应落在用户侧覆盖项，而不是改插件目录里的文件。

**失败信号（未来命中即该想起本条）**：任何"用户配置里写了 `cmd`/`is_proc`"的说法 → 先在用户配置根 `rg -n 'cmd'` 确认，再去 `lazy/sidekick.nvim/sk/cli/` 找真身。
