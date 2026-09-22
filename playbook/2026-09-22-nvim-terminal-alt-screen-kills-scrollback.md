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
verified_by: human
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

开关（本次记录的两条）：pi 在 `~/.pi/agent/settings.json` 的 `tuiMode` 起时传 `--tui-mode regular` 覆盖；
Claude Code 2.1.x 进备用屏，`CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` 关。

## 证据

- 同一 nvim 打 200 行的行数对照：主屏 **201** 行 / 备用屏 **28** 行（= winheight）。
- python `pty.fork` 抓原始输出、数 `\x1b[?1049h` 可判断程序是否进备用屏。
- 同一会话里 `script(1)` 起 claude 的两次失效：**拿不到字节**；以及在未信任目录会先出 trust 对话框、
  根本不进备用屏。→ 这条只说明 **`script(1)` 这个探针**在本场景不可用，不等于一般性的「探针都会改变被测行为」。

证据等级：`verified_by: human` —— 来源是会话内的 prose 摘要（`capture:…`），无命令转录。
`pty.fork` 数 `1049h` 的探针可当场重跑，跑通后可升回 `command`。

## 边界 / 反例

- 本条只覆盖「备用屏没有 scrollback」这一条机制。**其它**造成「终端输出回看不全」的成因不在范围内
  （例如输出被截断）——本条没有对它们作任何断言。
- `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN` 是本条记录到的那个环境变量；其取值与长期稳定性未核。
- `sidekick` 自带 scrollback 模块的行为，本次只观测到「只在 mux（tmux/zellij）能 dump pane 时生效」这一条；
  它内部怎么做到的不在本条范围内。
