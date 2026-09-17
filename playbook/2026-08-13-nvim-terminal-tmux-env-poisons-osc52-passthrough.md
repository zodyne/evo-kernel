---
id: nvim-terminal-tmux-env-poisons-osc52-passthrough
type: lesson
status: validated
scope: global
domain: terminal
tags: [nvim, tmux, osc52, clipboard, sidekick, env]
triggers:
  - "在 nvim :terminal 里跑 CLI（Claude Code / Hermes）选文本后冒出 '52;c;<base64>' 乱码"
  - "nvim 内嵌终端里 OSC 52 剪贴板序列被当普通文本画出来"
  - "排查 nvim :terminal 子进程继承外层 $TMUX / $TMUX_PANE 的副作用"
  - "sidekick tools 里给命令清环境变量（env={TMUX=false}）"
  - "裸 OSC 52 被静默消费正常，但带 tmux DCS passthrough 包装的序列漏成乱码（失败信号）"
created: 2026-08-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-13-12-51-30-178-h9oy
last_verified: 2026-08-13
superseded_by: null
schema_version: 1
related: [nvim-osc52-fallback-clipboard-garbled-in-tmux]
---

# 主张

nvim 的 `:terminal` 会把外层 `$TMUX` 原样传给子进程，导致 CLI（Claude Code / Hermes）误判自己直接跑在 tmux pane 里，把 OSC 52 剪贴板序列包进 tmux DCS passthrough（`\ePtmux;…\e\\`）。nvim 的 libvterm 不认这个包装，内层 payload 被当普通文本画在光标处——表现为选中输出时冒出 `'52;c;<base64>'` 乱码。

修法：sidekick tools 加 `env={TMUX=false, TMUX_PANE=false}`（sidekick 用 `false` 表示清除）。

# 判别方法

**裸 OSC 52 被 nvim 静默消费且剪贴板正常，passthrough 包装才漏**——用这条区分「终端/nvim 不支持 OSC 52」与「序列被多包了一层 tmux passthrough」。

# 为什么 / 定位关键

claude bundle 里 `R5()` 只看 `process.env.TMUX` 决定包不包 passthrough。所以问题不在 nvim 的剪贴板配置，也不在 libvterm 的 OSC 52 支持，而在 `:terminal` 传进子进程的那两个环境变量。

# 证据

实测 2026-08-13：清除前后同一脚本输出 `'COPY:52;c;5oiR…'` vs `'COPY:'`，且清除后 `pbpaste` 仍正确拿到解码文本。
