---
id: macos-log-show-large-window-timeout
type: lesson
status: validated
scope: global
domain: macos-diagnostics
tags: [macos, unified-logging, log-show, timeout, app-logs]
triggers:
  - "在 macOS 上用 log show 按关键词检索系统日志，命令跑到 300 秒超时"
  - "想查历史日志，一上来就把 --last 开到 3d/7d"
  - "log show --last 3d 卡住不返回，拿不到任何输出（失败信号）"
  - "app 自己有日志目录，纠结用统一日志还是直接 rg 文本日志"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b253-5635-7373-a922-2b2ad50891db
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

一句话主张：用 `log show` 检索 macOS 统一日志时别直接开大时间窗口——`log show --last 3d --predicate 'eventMessage CONTAINS[c] "..."'` 在本机跑到工具 300 秒上限仍无输出（`Command timed out after 300 seconds`），而 `--last 24h` 能正常返回；先把窗口收窄（24h 级别）并写更精确的 predicate，能直接读文本日志的 app 就绕过统一日志。

**为什么**：统一日志按时间窗口全量扫描，窗口越大、predicate 越宽（尤其 `eventMessage CONTAINS[c]` 这类全字段子串匹配），扫描代价越高；一旦撞上工具的硬超时，既拿不到结果也拿不到部分输出，等于白跑一次长命令。反之，很多 app 自己把可读日志写在容器/`~/Library/Logs` 下，`rg` 秒级可查。

**证据**（会话 01a0b253 命令↔结果切片）：
- `log show --last 24h --style compact --predicate 'process CONTAINS[c] "rdc" OR eventMessage CONTAINS[c] "rdp" OR eve...'` → 有返回（首行 `2026-09-18 09:52:21.072 Df distnoted[549:81065a] [com.apple.distnoted:diagnostic] register na...`）。
- `log show --last 3d --style compact --predicate 'eventMessage CONTAINS[c] "tangfuqiang"' 2>/dev/null | head -20` → `✗ Command timed out after 300 seconds`。
- 同一会话里查该 app 自己的日志目录（`~/Library/Containers/com.microsoft.rdc.macos/Data/Library/Logs/Windows App/`）用 `rg`/`tail` 都是即时返回，还据此定位到具体会话 id 的日志行。

**边界**：切片里两次 `log show` 的 predicate 不同（24h 那条是 `process CONTAINS` 的 OR 组合，3d 那条是 `eventMessage CONTAINS`），所以「超时全怪窗口大小」不能算严格对照；可确定的是这条 3d + 宽 predicate 的写法在本机必超时，先用小窗口是安全策略。另外 24h 那条虽然返回了，但首行是 `distnoted` 的无关记录——宽 predicate 会匹配到噪音，拿到输出不等于是你要找的东西，命中内容还要再筛。`log show` 的输出如果还要接 `head`/`rg`，注意失败（超时）会在管道里表现为空结果。
