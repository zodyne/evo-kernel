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
verified_by: human
source: capture:inbox/capture-2026-09-21-07-51-49-525-yil1
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [tmux-continuum-save-needs-status-bar-rendering]
---

# tmux 里连写 `kill-window -t <索引>` 会打错窗口：`renumber-windows=on` 下索引在删除后立即前移

**主张**：在 `renumber-windows=on` 的配置下，**第一条 `kill-window` 删完，索引立即前移**，
于是第二条 `-t main:2` 命中的是**原来的 3 号**。
要精确关窗口，用 **window id**（`tmux list-windows` 显示的 `@NN`，如 `-t main:@12`）——
这是本次事后确认的做法，不依赖索引。capture 另提到「临时 `set -g renumber-windows off`」，
但**没有验证过**关掉之后按索引关是否就安全（见边界）。

## 证据（一次事故的复盘，样本量 1）

- 本想关 1、2 号（两个 zsh），实际关掉了 **1 号 zsh 和 3 号 nvim**。
- 事后确认的做法：用 `tmux list-windows` 取 `@NN`。capture 另记录了「临时 `set -g renumber-windows off`」
  这个动作，但没有对「关掉之后按索引关是否安全」作过验证——**本条不把 `off` 当作已确认的解法**。

证据等级：`verified_by: human` —— 来源是会话内的事故口述（`capture:…`），无命令转录、样本量 1。
**未经本机复核** —— `command` 档要求命令级可复现证据，本条没有。

## 边界 / 反例

- 前移观测是在 **`renumber-windows=on`** 下取得的。本条**不假定**这是 tmux 的默认值——
  要按索引批量关窗口前，先 `show -g renumber-windows` 确认当前配置。
- **只实测了删除**（`kill-window`）触发前移；新增窗口是否同样触发索引重排，本次没有观测。
- 「`off` 时按索引关就是安全的」不是观测结论——capture 只给了「临时 set off」这个动作，
  没有对 `off` 下的行为作过验证。本条不对 `off` 行为下断言。
- 其它按索引定位的子命令（`select-window`、`swap-window` 等）**未测**；capture 只提过 `kill-window`。
