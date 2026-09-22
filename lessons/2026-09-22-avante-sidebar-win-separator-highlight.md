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
verified_by: human
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

## 独立复核与证据快照（2026-09-22）

本条**不进注入集**（`lessons` 候选），原因是证据快照已变，不是主张被推翻。复核结论：

- `verified_by` 由 `command` 降为 `human`：引用命令在切片里被截断、**不能照抄重跑**，
  证据绑在别仓/临时环境的一次输出上，按本库口径只算「当时跑过」。
- **快照漂移**：——（本条不是快照漂移，是**核心主张写反了**，见下）
- 范围：

## ⚠ 2026-09-22 独立复核：原核心主张**写反了**，本条已按复验结果改写

**原文写的是**：该组「运行时默认只有 `link = WinSeparator`、自身 `fg=nil`」「实际颜色默认由
`WinSeparator` 决定」。**复验结果是相反的**：

- plugin 源码 `lua/avante/highlights.lua:28-31` 定义
  `AVANTE_SIDEBAR_WIN_SEPARATOR = { name = "AvanteSidebarWinSeparator", fg_link_bg = "NormalFloat", bg_link = "NormalFloat" }`
  —— **没有 `link` 字段**。
- `setup()`（同文件 `:96-106`）据此算出 `fg = Utils.get_hl("NormalFloat").bg`、`bg = 同上`、
  `link = hl.link or nil` ⇒ **默认 `link = nil`**。
- 本配置 `transparency = true` 时 `NormalFloat` 无 `bg` ⇒ 该组最终是**空组** ⇒ 侧栏
  `winhl "WinSeparator:AvanteSidebarWinSeparator"` 回落到 `Normal` 前景，
  分隔线呈 `#bfc6d4`（而非 `WinSeparator` 的 `#383747`）。

**更正后的主张**：`AvanteSidebarWinSeparator` 的默认**不是** `link=WinSeparator`；它由插件按
`fg_link_bg`/`bg_link` 取 `NormalFloat` 的**背景色**当自己的前景/背景，透明主题下 `NormalFloat`
无 `bg` ⇒ 该组为空 ⇒ 分隔线落回 `Normal` 前景。要改分隔线颜色，覆盖 `AvanteSidebarWinSeparator`
本身即可（本配置的 `ui.lua:44-49` 注释写的是对的，提案却写成了反的）。

## 更值钱的教训：这条是**循环证据**的标本

原提案引的「运行时 `link = WinSeparator`」读数，来源是**本次会话自己**在
`config/nvim/lua/configs/ui.lua:50` 写的 `nvim_set_hl(0, "AvanteSidebarWinSeparator", { link = "WinSeparator" })`
—— 即它**读回了自己刚写的覆盖**，然后当成"插件的默认值"记录下来。
`base46`/`NvChad` 均不设该组，用户配置里这一行是唯一出处。

**可迁移的判据**：判断"某插件的默认高亮/默认行为"时，先隔离自己的配置再读
（本条的复验做法就是临时去掉 `ui.lua` 的覆盖后跑 headless），否则会把**自己的覆盖**
当成插件的默认，写出一条**方向相反**的经验。

- `verified_by: human`：运行时证据依赖已删除的 `/tmp/shot_*.lua` 与 dotfiles 的当时分支；
  源码 grep 可复跑，但真值绑在插件版本上。**不进注入集**，待插件升级后复核再考虑提升。
- 原边界节里「组名被截断未确认」那条已复验：`AvanteSidebarWinHorizontalSeparator` 才是
  带 `fg_link = "WinSeparator"` 的那个组。

> **同源（n 记账）**：本条与同一会话 `eef619c9` 的另 1 条提案同源于nvim 高亮那一组排查——**一次观测被拆成多条**，别当独立经验计权。
> 更大一层：2026-09-18 那批有 3 个会话在 **33 秒内**先后启动、切片里「首条 user」逐字相同（对同一份 PLAN.md 的并行符合性审计），所以 A/B 两簇 12 条的**有效独立来源 ≈2 次**，不是 12 次。
> 另：`evo slice` 会**截断长命令**——凡依赖被截断部分的引用，只能算「当时跑过」。
