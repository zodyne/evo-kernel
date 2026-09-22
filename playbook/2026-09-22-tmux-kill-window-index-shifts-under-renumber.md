---
id: tmux-kill-window-index-shifts-under-renumber
type: playbook
status: validated
scope: global
domain: macos-tooling
tags: [tmux, window-index, renumber-windows, kill-window, window-id]
triggers:
  - "在 tmux 里连写多条 kill-window -t <索引>，关掉的不是预期的窗口"
  - "想批量关几个窗口，结果误关了旁边的窗口"
  - "renumber-windows=on 时窗口索引会在每次删除后前移"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:inbox/capture-2026-09-21-07-51-49-525-yil1
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [tmux-continuum-save-needs-status-bar-rendering]
---

# tmux 里连写 `kill-window -t <索引>` 会打错窗口：`renumber-windows=on` 下索引在删除后立即前移

**主张**：`renumber-windows=on`（默认常见配置）时，**第一条 `kill-window` 删完，索引立即前移**，
第二条 `-t main:2` 命中的是**原来的 3 号**。要精确关窗口用 **window id**（`tmux list-windows` 显示的
`@NN`，如 `-t main:@12`），或临时 `set -g renumber-windows off`。

## 为什么

索引是**位置**、window id 是**身份**。批量操作里只要中间发生了增删，位置就会重排；
这与 shell 里「按行号删」而文件在变是同一类错误。`@NN` 一经分配不再变，是稳定的身份键。

## 证据（本会话实测）

- 本想关 1、2 号（两个 zsh），实际关掉了 **1 号 zsh 和 3 号 nvim**。
- 修法：用 `tmux list-windows` 取 `@NN`，或临时关掉 renumber。

## 边界 / 反例

- `renumber-windows=off` 时索引不重排，按索引关是安全的 —— 但**默认值随配置与版本而异**，
  不能假定；要么先 `show -g renumber-windows` 确认，要么一律用 `@NN`。
- 本条针对 `kill-window`；其余按索引定位的 tmux 子命令（`select-window`、`swap-window`）同理，
  但未逐条实测。
