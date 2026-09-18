---
id: zsh-history-epoch-timestamp-decode-date-r
type: lesson
status: validated
scope: global
domain: shell
tags: [zsh, zsh-history, timestamp, date, forensics, macOS]
triggers:
  - "要还原『某条命令 / 某个 nvim 是几点敲的』，手上有 ~/.zsh_history"
  - "历史条目形如 `: 1789375514:0;nvim`，不知道前缀数字是什么（失败信号）"
  - "把 shell 历史与 nvim.log / 会话文件 mtime 对齐做时间线取证"
  - "在 ~/.zshrc 里 grep 不到 HISTFILE / EXTENDED_HISTORY，就以为历史功能没开（失败信号）"
  - "跨平台脚本里用 date -r 解时间戳"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ad-7b8a-725c-a75a-f98b5e86a96a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [launchd-log-utc-timezone-trigger-check]
---

# `.zsh_history` 的时间戳是 epoch 秒，macOS 上用 `date -r <epoch>` 解码后再与日志时间线对齐

**主张**：zsh 扩展历史格式下，`~/.zsh_history` 每条形如 `: <epoch秒>:<执行耗时>;<命令>`（例：`: 1789375514:0;nvim`），前缀数字不是"行号/序号"而是 epoch 秒。macOS 上用 `date -r <epoch> "+%Y-%m-%d %H:%M:%S %Z"` 把它解码成本地时间（本机 CST），才能与 nvim.log 行内的 ISO 时间戳、pi 会话文件 mtime 放在同一条时间线上。顺带：这类格式由 oh-my-zsh 默认库开启，**用户 `~/.zshrc` 里 grep 不到 history 配置不代表历史没开**。

**为什么**：法证/复盘时要回答"这个进程/会话是哪次敲命令拉起来的"，shell 历史是唯一带人工意图的时间源，但它的时间戳是可读性为零的 epoch；不先解码就无法与日志对齐，容易按"看到 16:45 就以为 16:45"的直觉错位。

**证据（本会话命令 ↔ 结果）**：
- `for e in 1789375412 1789375514 1789375533 1789375537 1789375729 1789376759; do printf "%s -> " "$e"; date -r $e "+%Y-%m-%d %H:%M:%S %Z"; done`
  → `1789375412 -> 2026-09-14 16:43:32 CST`、`1789375514 -> 2026-09-14 16:45:14 CST`、`1789375533 -> 2026-09-14 16:45:33 CST`、`178937…`
- `rg -n '1789375412|1789375514|1789375533|1789375537|1789375729|1789376759' /Users/zodyne/.zsh_history`
  → `2159:: 1789375412:0;clear`、`2160:: 1789375514:0;nvim`、`2161:: 1789375533:0;cd`、`2162:: 1789375537:0;nvim`（条目形状 `: <epoch>:<耗时>;<cmd>`）。
- 同段会话文件的 mtime 落在这条时间线上：`stat -f '%Sm %N' …` → `2026-09-14T16:46:28 2026-09-14T08-45-46-798Z_01a09f18-…jsonl`。
- 配置来源不在用户 rc：`wc -l ~/.zshrc` → `165`；`rg -n 'SHARE_HISTORY|INC_APPEND|HISTFILE|setopt|hist' ~/.zshrc` 只命中注释行（`# stamp shown in the history command output.`、`77:# HIST_STAMPS="mm/dd/yyyy"`）；而 `rg -n 'setopt|HISTFILE|SAVEHIST' ~/.oh-my-zsh/lib/history.zsh` → `38:[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"` 等。

**反例/边界**：
- BSD/macOS 的 `date -r` 接 epoch 秒；GNU `date -r` 是"按文件 mtime 输出"，跨平台脚本不能照抄。
- 条目里的耗时为 `0` 只表示未记录到非零耗时，不代表命令没执行/秒退。
- 本会话只证明了"epoch 可解码 + 与同段会话文件 mtime 同时间窗"；"某次 nvim 启动 = 某条历史"的严格一一归属未在切片中闭合，别把它当已证事实引用。

**失败信号（未来命中即该想起本条）**：历史条目以 `: <数字>:` 开头而你把它读成行号/计数；或 `.zshrc` 里没有 history 相关 setopt 就下结论说历史功能没开。
