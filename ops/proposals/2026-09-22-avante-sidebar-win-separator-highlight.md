---
id: avante-sidebar-win-separator-highlight
type: fact
status: candidate
scope: global
domain: nvim
tags: [avante, nvim, highlight, winseparator, sidebar]
triggers:
  - "改 avante.nvim 侧栏/聊天窗分隔线的颜色，找不到该覆盖哪个高亮组"
  - "在自己 nvim 配置里 grep WinSeparator/VertSplit/Avante，找不到 avante 侧栏分隔线的高亮名（失败信号：自有配置 0 命中）"
  - "要给 avante 写 hl_override/自定义高亮，组名疑似 AvanteSidebarWinSeparator"
  - "avante 侧栏分隔线颜色跟随了别处，想知道它默认 link 到哪"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:eef619c9-264d-407b-8546-78af563a59ec
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [nvim-render-verify-via-tmux-capture-pane, nvim-config-live-dir-is-dotfiles-symlink]
---

# avante.nvim 侧栏分隔线高亮组是 `AvanteSidebarWinSeparator`，默认只 `link` 到 `WinSeparator`

**主张**：avante.nvim 的侧栏/聊天窗分隔线高亮组名是 `AvanteSidebarWinSeparator`，定义在插件自带的 `lua/avante/highlights.lua`（第 29 行），运行时默认只有 `link = WinSeparator`、自身 fg=nil。要在用户配置里覆盖它，得知道 avante 内部的组名；它的实际颜色默认由 `WinSeparator` 决定。

**为什么**：本次在用户 nvim 配置里 grep `WinSeparator|VertSplit|Avante`（排除 `plugins/avante.lua` 后）是 0 命中——avante 侧栏的分隔线组名只存在于插件源码里，不查插件目录就找不到该覆盖哪个组；且因为是 link，只覆盖组本身还是覆盖 `WinSeparator` 会得到不同行为。

**边界/反例**：同文件第 34 行还有另一个 `AvanteSide...` 开头的组（切片里名字被截断，未确认），水平方向分隔线可能走那个组——本条目只断言垂直分隔线的组名与 link。组名与 link 目标是插件版本相关的，升级 avante 后需重新核对。

**证据（会话切片 eef619c9，命令 ↔ 结果）**：
- 用户配置 grep 0 命中：`grep -rn "WinSeparator\|VertSplit" --include='*.lua' . ; echo "---AVANTE---"; grep -rn "Avante" --include='*.lua' . | grep -v "plugins/avante.lua"` → `---AVANTE---`（无输出）。
- 插件源码定义：在 `~/.local/share/nvim/lazy/avante.nvim` 跑 `grep -rn "WinSeparator\|HorizontalSeparator\|SidebarWin" --include='*.lua' lua/` → `lua/avante/highlights.lua:29:    name = "AvanteSidebarWinSeparator",`。
- 运行时实测：真实 nvim 探针输出 `AvanteSidebarWinSeparator link=WinSeparator fg=nil`；同轮另一次探针输出 `avante{link=WinSeparator} winsep{fg=#383747}`（目标组 WinSeparator 的 fg=#383747）。
