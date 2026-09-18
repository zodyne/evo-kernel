---
id: nvim-log-lines-carry-pid-for-instance-attribution
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, nvim-log, pid, forensics, log-attribution]
triggers:
  - "排查 nvim 报错/警告日志，想确认是哪次启动的实例产生的"
  - "nvim.log 里混着多个实例的行，按时间戳猜归属（失败信号）"
  - "nvim 已经退出、ps 里找不到进程，还要定位它的日志行"
  - "想按 pid 过滤 ~/.local/state/nvim/nvim.log"
  - "对齐 nvim 日志与 shell 历史 / 会话文件 mtime 的时间线"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ad-7b8a-725c-a75a-f98b5e86a96a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [flatten-nvim-nest-headless-crashes-host, debug-nvim-lsp-via-live-server-socket]
---

# `nvim.log` 每行内嵌产生它的 nvim 进程 pid（`ui.<pid>`），按 pid 切分才能把日志归属到实例

**主张**：`~/.local/state/nvim/nvim.log` 的日志行形如 `<LEVEL> <ISO时间> ui.<pid> <文件>:<行>: <消息>`，行内直接带 pid（例：`WRN 2026-09-14T16:47:29.111 ui.31043   tui_handle_term_mode:226: …`）。所以即使某个 nvim 实例早已退出、`ps` 里查不到，仍可把日志行归属到具体实例：先拿候选 pid（活进程用 `ps -eo pid,lstart,command`，已退出的从 shell 历史/会话里取），再 `rg -n '<pid1>|<pid2>' nvim.log` 过滤；多实例日志混在一起时按 `ui.<pid>` 分组读，别按时间戳相近就归到同一个实例。

**为什么**：nvim 的日志是多个实例追加写的同一个文件，同一条 TUI/插件告警在时间上可能紧邻另一个实例的行；pid 是行级唯一的归属键，比"大概这个时间点只有我在用 nvim"稳。且实例退出后日志仍在，pid 是唯一还活着的指针。

**证据（本会话命令 ↔ 结果）**：
- `rg -n '34667|34804|34876|31043' /Users/zodyne/.local/state/nvim/nvim.log | head`（另接 `rg -n 'embed' …`）
  → `603:WRN 2026-09-14T16:47:29.111 ui.31043   tui_handle_term_mode:226: TUI: terminal mode 69 unavailable, state 0 604:WRN …` —— 四个候选 pid 中只有 31043 命中，说明可按 pid 精确切分。
- 另一个实例：`sed -n '660,701p' ~/.local/state/nvim/nvim.log` → `WRN 2026-09-14T20:17:44.038 ui.66036   tui_ha…`（同一行同时给 ISO 时间戳与 pid）。
- 活进程一侧：`ps -eo pid,lstart,command | rg '[n]vim' | head -10` → `9690 Tue Sep 15 10:51:46 2026     nvim --embed`、`22531 Wed Sep 16 08:46:37 2026     node /Users/zodyne/.local/share/nvim/…`（BSD ps 的 `lstart` 给完整启动时间；`[n]vim` 的方括号写法避免 rg 匹配到自身）。

**反例/边界**：
- 本条只从切片里的日志行证实了"行内含 pid"+"可按 pid 过滤"；从 pid 反查"是哪次启动、对应哪条 shell 历史/哪个会话"的完整链路在本会话里没有闭合（切片止于过滤出 31043 的行）。
- nvim.log 的时间戳没有时区后缀，跨时区比对要另做换算；`lstart` 是 BSD 方言的 ps 关键字。
- `ui.<pid>` 是本机 nvim 0.12.x 的日志前缀形态，换版本/换 `log_level` 后要重新确认格式再按此解析。

**失败信号（未来命中即该想起本条）**：准备用"这几行时间挨着"来论证某条 nvim 日志出自哪个实例，而日志行里明明有 `ui.<pid>` 没用。
