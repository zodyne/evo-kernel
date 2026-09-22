---
id: nvim-hl-link-fg-nil-means-inherited
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, highlight, nvim_get_hl, link, probe]
triggers:
  - "nvim 高亮探针读到某组 fg=nil，据此断定插件没设颜色"
  - "探针输出里出现 link=<某组>、fg=nil（失败信号：以为该组无前景色）"
  - "插件高亮继承/链接到默认组，要拿它的有效色写进结论"
  - "排查 nvim 配色不生效，需要区分『没设色』与『link 到别组』"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:eef619c9-264d-407b-8546-78af563a59ec
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [avante-sidebar-win-separator-highlight, nvim-render-verify-via-tmux-capture-pane]
---

# 高亮组读到 `link=<目标>、fg=nil` 是「继承」，不是「没颜色」

**主张**：nvim 里一个高亮组若 `link` 到别的组，读组本身得到的是 `link=<目标组>、fg=nil`；这个 fg=nil 表示「跟随 link 目标」，不代表该组没有前景色——只看 fg 会把「继承默认组」误判成「插件没设色」。要判断有效色，必须顺着 link 读目标组（或直接抓渲染结果）。

**为什么**：本次探针在同一实例上连续读到 `AvanteSidebarWinSeparator link=WinSeparator fg=nil`、`avante{link=WinSeparator} winsep{fg=#383747}`、`baseline: link=WinSeparator fg=nil bg=nil`；而 link 目标 `WinSeparator` 的 fg 实测为 `#383747`。颜色一直在，只是不在被 link 的组上——只读组本身就会得出「avante 没给分隔线设色」的错误结论。

**边界/反例**：link 可能多级，读到中间组仍是 link；`fg=nil` 也确实可能是真的无前景色（组未定义且无 link），要区分必须看有没有 `link=` 字段并解引用到链尾。取得有效色的手段以本会话证据为准：读 link 目标组的属性（`winsep{fg=#383747}`），或按 `nvim-render-verify-via-tmux-capture-pane` 抓真实渲染。

**证据（会话切片 eef619c9，命令 ↔ 结果）**：
- 真实 nvim 探针：`=== log2 === colors_name=nil AvanteChat ok=true  AvanteSidebarWinSeparator link=WinSeparator fg=nil AFTER colorscheme: l...`
- 同一探针链的另一轮：`t=4s colors_name=nil  avante{link=WinSeparator} winsep{fg=#383747} t=12s after AvanteChat: avante{link=WinSeparator} win...`
- ColorScheme 前后对照：`baseline:          link=WinSeparator fg=nil bg=nil after ColorScheme: link=WinSeparator fg=nil bg=nil === render after C...`
