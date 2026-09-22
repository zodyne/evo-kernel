---
id: nvim-hl-link-fg-nil-means-inherited
type: lesson
status: validated
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

## 复核证据（2026-09-22，本机重跑 —— 本条据此进注入集）

原提案的证据来自已删除的 `/tmp/shot_*.lua` 探针（切片里命令体被截断），且只观测了**一个**组。
下列是**自足一行**，不依赖任何插件或沙箱，可当场重跑：

```
$ nvim --headless -c 'lua vim.api.nvim_set_hl(0,"A",{link="B"}); print(vim.inspect(vim.api.nvim_get_hl(0,{name="A"})))' -c 'qa!'
{ link = "B" }                          ← 读 link 组：只有 link=，没有 fg

$ nvim --headless -c 'lua vim.api.nvim_set_hl(0,"A",{link="B"}); vim.api.nvim_set_hl(0,"B",{fg=0xff0000}); print(vim.inspect(vim.api.nvim_get_hl(0,{name="A",link=false})))' -c 'qa!'
{ fg = 16711680 }                       ← 跟进 link 目标（或 link=false）才拿到有效色
```

**范围收窄**：原正文「一个高亮组若 link 到别的组，读组本身得到 link=、fg=nil」是从**同一个组**
的几次读数升格出的全称句；上表把它变成了可复跑的最小证据（两个方向都在），
但「所有组都如此」仍只由 nvim 的 `nvim_get_hl` 语义支撑，不是逐组验证过。

> **同源（n 记账）**：本条与同一会话 `eef619c9` 的另 1 条提案同源于nvim 高亮那一组排查——**一次观测被拆成多条**，别当独立经验计权。
> 更大一层：2026-09-18 那批有 3 个会话在 **33 秒内**先后启动、切片里「首条 user」逐字相同（对同一份 PLAN.md 的并行符合性审计），所以 A/B 两簇 12 条的**有效独立来源 ≈2 次**，不是 12 次。
> 另：`evo slice` 会**截断长命令**——凡依赖被截断部分的引用，只能算「当时跑过」。
