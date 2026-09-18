---
id: pmset-log-sleep-keyword-noise-anchored-filter
type: lesson
status: candidate
scope: global
domain: macos
tags: [macos, pmset, sleep, log, grep, forensics]
triggers:
  - "排查进程/任务卡了半小时以上，想排除『机器睡过』这个替代解释"
  - "pmset -g log | grep -E 'Sleep|Wake' 捞出的行不是睡眠事件（失败信号：Wake Requests / Assertions 断言行、别的日期的行）"
  - "要按本地时间窗口确认某时段有没有 Sleep/Wake/DarkWake"
  - "过滤 macOS 系统日志时只用了关键词，没有锚定行首时间戳与状态词"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09e85-e0fb-75a9-9255-6adde3fc97aa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: []
---

**主张**：查 macOS 睡眠/唤醒历史时，只用关键词过滤 `pmset -g log`（`grep -E "Sleep|Wake"`）不可靠——会捞到 `Wake Requests`、`Assertions` 之类的断言行，甚至来自别的日期。必须锚定行首时间戳与状态词：

```
pmset -g log | grep -E "^YYYY-MM-DD [0-9:]+ \+0800 +(Sleep|Wake|DarkWake)"
```

再裁到目标时间窗口。

**为什么**：`pmset -g log` 是逐事件的系统日志，很多行的正文/发起者里带 Sleep/Wake 字样（唤醒请求、电源断言），关键词命中 ≠ 睡眠事件。用它排除"机器睡过"这个替代解释时，噪音行会把结论带偏。

**证据**（本会话命令 ↔ 结果）：
- 关键词过滤（O）：`pmset -g log 2>/dev/null | grep -E "Sleep|Wake" ...` → 输出首行是
  `2026-09-10 21:53:27 +0800 Wake Requests [process=mDNSResponder requ...`，不是 09-14 12:30–13:50 目标窗口的睡眠事件。
- 修正过滤（O2）：`pmset -g log 2>/dev/null | grep -E "^2026-09-14 [0-9:]+ \+0800 +(Sleep|Wake|DarkWake)" | head -30` →
  `2026-09-14 00:11:08 +0800 Sleep  Entering Sleep state due to 'Clamshell...` 等 09-14 的真实 Sleep/Wake/DarkWake 事件。
- 窗口复核：`12:00–14:00` 用锚定过滤 → 空（该窗口内没有睡眠），据此排除了"机器睡过"这个替代解释。

**边界/反例**：锚定过滤依赖 `pmset -g log` 行首的时间戳+状态词格式；`Wake Requests` / `Assertions` 行本身对其它排查（谁在阻止睡眠）有价值，只是不能当睡眠事件计数。本条不主张"别用关键词 grep pmset"，而是"关键词 grep 的输出不能直接当事件列表"。
