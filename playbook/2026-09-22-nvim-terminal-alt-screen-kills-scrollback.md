---
id: nvim-terminal-alt-screen-kills-scrollback
type: playbook
status: validated
scope: global
domain: nvim-tooling
tags: [nvim, terminal, alternate-screen, scrollback, cli-agent, libvterm]
triggers:
  - "nvim 的 :terminal 里跑 CLI agent，滚到顶就滚不动了（buffer 行数恰好等于窗口高度）"
  - "想回看 :terminal 里 agent 的历史输出，却发现一屏之前的全没了"
  - "判断某个 TUI 程序是不是进了备用屏（CSI ?1049h）"
  - "CLI agent 在 nvim 终端里没有 scrollback，想找一个开关把它关掉"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:inbox/capture-2026-09-18-09-18-59-865-vdx6
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [nvim-tty-probe-more-pager-blocks, nvim-terminal-tmux-env-poisons-osc52-passthrough]
---

# :terminal 里 CLI agent 滚不动 = 它进了备用屏：libvterm 不为备用屏留 scrollback

**主张**：nvim `:terminal` 里 CLI agent「到顶滚不动」的成因是程序进了**备用屏**（`CSI ?1049h`）：
libvterm 只把主屏滚出顶部的行推进 scrollback，备用屏一行不留，于是 nvim buffer 行数恒等于窗口高度。
同一 nvim 打 200 行验证：主屏 201 行 / 备用屏 28 行（= winheight）。
开关：pi 在 `~/.pi/agent/settings.json` 的 `tuiMode`（默认 `fullscreen`，起时传 `--tui-mode regular` 覆盖）；
Claude Code 2.1.x 默认进备用屏，`CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` 关闭。

## 为什么

scrollback 是「主屏滚出的行」这一事件的产物；备用屏按终端语义就是**不滚动**的全屏画布，
libvterm 忠实实现了这一点。所以这不是 nvim 的 bug，也不是 agent 的 bug，而是两种终端模型的碰撞。
`sidekick` 自带的 scrollback 模块只在 mux（tmux/zellij）能 dump pane 时才生效——它绕开了 libvterm。

## 证据（本会话实测）

- python `pty.fork` 抓原始输出、数 `\x1b[?1049h` 可证程序是否进备用屏。
- `script(1)` 起 claude **拿不到字节**；且在未信任目录会先出 trust 对话框、根本不进备用屏——
  探针本身会改变被测行为，取证要用 pty 直连。

## 边界 / 反例

- 只覆盖「备用屏 = 无 scrollback」这一机制；程序自己不进备用屏而输出被截断，是另一回事。
- `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN` 的取值与是否稳定，随 Claude Code 版本变，用前核当前版本。
- mux 场景下（tmux/zellij）另有 pane 级 scrollback，本条不覆盖那条路径。
