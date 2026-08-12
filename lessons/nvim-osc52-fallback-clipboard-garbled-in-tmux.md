---
id: nvim-osc52-fallback-clipboard-garbled-in-tmux
type: lesson
status: candidate
scope: global
domain: terminal
tags: [nvim, tmux, osc52, clipboard]
triggers:
  - "在 tmux 里的 nvim 选择/yank 文本后屏幕出现乱码或逃逸序列"
  - "nvim 升级到 0.11+ 后剪贴板/选择行为异常"
  - "yank 时终端打出一大段可疑字符（失败信号：疑似 OSC 52 序列未被透传）"
  - "排查 nvim 剪贴板 provider 回退/终端剪贴板集成问题"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fb1f9-a81e-764d-8811-87dd56da1cc6
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
---

**主张**：nvim ≥0.11 在找不到系统剪贴板工具时**自动回退用 OSC 52 写剪贴板**（行为变更，官方 news.txt 原文佐证）。tmux 会话里 nvim 选择/yank 出现乱码逃逸序列时，先确认这三件事再怀疑终端：`nvim --version` 是否 ≥0.11、`echo $TMUX` 是否在 tmux 内、`grep -i "osc 52" $VIMRUNTIME/doc/news.txt` 确认回退行为——这是 0.11 引入的已知行为变更撞上终端透传链问题，不是终端/配置坏了。

**证据**：会话中 `nvim --version` 输出 `NVIM v0.11.5`；`echo $TMUX` 确认在 tmux 3.6a 内、`TERM=xterm-256color`；`grep -n -i "osc 52" /opt/homebrew/share/nvim/runtime/doc/news.txt` 命中 143 行原文 "OSC 52 is used as a fallback clipboard provider when no other clipboard-tool is found, even when not using..."。用户原始症状即"nvim 中选择会话内容出现乱码"（附截图）。

**边界**：切片只坐实了"0.11+ 有 OSC 52 回退行为"这一机制与排查路径；具体修复（装剪贴板工具 / tmux `set -g set-clipboard on` / 显式 `vim.g.clipboard`）未在切片中出现命令级验证，修复侧不要凭本条直接照抄。
