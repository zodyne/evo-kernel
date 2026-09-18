---
id: pi-session-file-utc-name-vs-local-mtime
type: lesson
status: candidate
scope: global
domain: session-forensics
tags: [pi, session-jsonl, timestamp, timezone, mtime, timeline]
triggers:
  - "拿 pi 会话文件名 `<UTC 时间戳>_<uuid>.jsonl` 里的时间当会话发生时刻"
  - "把 `ls` / `stat` 显示的 mtime 与文件名里的时间直接相减、直接比大小"
  - "对齐多份会话/日志时间线时出现整小时的系统性偏移（失败信号：差值正好是时区偏移）"
  - "判断某个会话何时结束/被杀，需要一条可靠的时间线"
  - "看到会话文件 mtime 比文件名晚好几小时，怀疑文件在会话结束后又被改过（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e5eb-725c-a75a-f980f1444774
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [launchd-log-utc-timezone-trigger-check, nvim-log-lines-carry-pid-for-instance-attribution]
---

# pi 会话文件名的时间戳是 UTC，而 ls/stat 的 mtime 是本地时间——时间线取证必须先换算时区

**主张**：pi 会话 jsonl 的文件名时间戳按 **UTC** 记（`2026-09-14T08-45-46-798Z_<uuid>.jsonl`，与文件内首条 `session` 事件逐毫秒相同），而 `ls -la` / `stat` 给出的 mtime 是**本地时间**。两侧直接比较会差一个整时区偏移（本机 +08:00 时差 8 小时），会把"会话结束那一刻"误读成"会话结束后 8 小时文件又被写过"。做会话/日志时间线取证时，先把两侧换算到同一时区再比。

**证据（切片 `01a0a7aa-e5eb-725c-a75a-f980f1444774`，逐字引用）**：

1. 同一文件的两个读数（同一台机器、同一条命令的结果里）：
   - `ls -la --time-style=full-iso ... 2026-09-14T08-4*.jsonl` →
     `-rw-r--r--@ 1 zodyne  staff    34698 Sep 14 16:46 2026-09-14T08-45-46-798Z_01a09f18-05ae-7485-85f6-b4efb9c12374.jsonl`
   - `stat -f "%N mtime=%Sm" -t "%Y-%m-%dT%H:%M:%S" 2026-09-14T08-4*.jsonl` →
     `2026-09-14T08-45-46-798Z_01a09f18-05ae-7485-85f6-b4efb9c12374.jsonl mtime=2026-09-14T16:46:28`
2. 文件名时刻 = 会话内首条事件时刻（同一文件的 ordered event log 第 1 行、`header events` 均为该时刻）：
   `1	2026-09-14T08:45:46.798Z	session`
3. mtime 换算回 UTC 后 ≈ 会话最后一笔写盘（LAST 3 EVENTS VERBATIM 中末条 `"timestamp":"2026-09-14T08:46:25.`）：`16:46:28`(本地) − 8h = `08:46:28Z`，比末条事件晚 3 秒。
4. 本机偏移为 +08:00，同切片 git 记录佐证：`b8a8e60 2026-09-04T13:11:15+08:00`。

**为什么容易踩**：文件名侧带 `Z`、`stat`/`ls` 侧不带任何时区标记（`-t` 格式串还能被写成读者以为的"UTC 格式"），两侧看起来是同一个 ISO 时间串，但一个 UTC 一个本地；差 8 小时又刚好不像"明显错误"，容易被解释成"进程结束后还有收尾写盘"。判据是**差值正好等于整时区偏移**（尤其 8 小时），出现这种系统性偏移就先怀疑时区，而不是怀疑文件被改写。

**边界 / 证据强度**：
- `verified_by: command`：上述读数、事件时间戳、git `+08:00` 全部来自切片里的命令输出，未依赖记忆。
- 只在 macOS + 本机 +08:00 下验证；其他时区/平台差值是同一个机制但数值不同。
- 切片**未验证**任何替代命令（如显式指定 `TZ=UTC` 或 `stat` 的 UTC 选项），所以本条不推荐具体 flag——照抄未经本会话验证的 flag 正是要避免的事。
- 同类坑在 `launchd-log-utc-timezone-trigger-check`（launchd 日志时间戳为 UTC）已记过一次；本条是 pi 会话文件这一侧的同类信号，故建 `related`。
