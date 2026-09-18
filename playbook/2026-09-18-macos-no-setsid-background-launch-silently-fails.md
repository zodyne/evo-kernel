---
id: macos-no-setsid-background-launch-silently-fails
type: lesson
status: validated
scope: global
domain: shell
tags: [macos, setsid, nohup, background-job, silent-failure, launch, caffeinate]
triggers:
  - "在 macOS 上用 `setsid nohup <cmd> >> log 2>&1 &` 启动后台长任务/守护进程"
  - "命令看似执行了，但没有进程、没有锁文件、日志不增长（失败信号）"
  - "重定向的启动留档只有几十字节且再无输出（失败信号）"
  - "同一段后台启动脚本 Linux 好使、macOS 上什么都不发生"
  - "要让蒸馏/批处理在终端退出后继续跑并顺带防睡眠"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae1e-1763-764c-a77e-51771fbd8c10
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [macos-no-timeout-command]
---

# macOS 没有 `setsid`：`setsid nohup … &` 启动后台任务会整条失败，错误只留在重定向文件里

**主张**：macOS 自带 userland **不含 `setsid`**（Linux 的 util-linux 才有）。在 macOS 上写 `setsid nohup CMD >> log 2>&1 &`，`setsid` 直接 `command not found`，整条启动**根本没有发生**；而 stderr 已被 `2>&1` 收进重定向文件，前台看不到任何报错，只留下一个几十字节的留档文件和"启动了但什么都没有"的假象（无进程、无锁、无日志）。正确写法是 `nohup CMD >> log 2>&1 &`；要脱离终端会话且防睡眠时用 `caffeinate -i -w <pid>` 包一层。

**证据（2026-09-17 本机）**：
- `which setsid || echo "setsid 不存在（macOS）"` → `setsid 不存在（macOS）`；同时 `ls -la ops/log/distill-runner.out` 显示该留档只有 **37 字节**（`Sep 17 15:40`），之后再无增长。
- 用 `setsid nohup …` 启动后：`pgrep -fl "evo-distill"` 无输出、`锁: (无锁)`、日志尾还停在此前更早的一条记录（`2026-09-17T07:21:49Z timeout …`）。
- 去掉 `setsid` 用 `EVO_DISTILL_TIMEOUT=1800 nohup ./ops/bin/evo-distill.sh --max 200 >> ops/log/distill-runner.out 2>&1 < /dev/null &` 重试，立刻拿到后台进程 `9611 /bin/bash -c cd /Users/zodyne/Dev/evo-kernel && EVO_DISTILL_TIMEOUT=1800 nohup ./ops/bin/evo-distill.sh --max 200 >`；此后检查为 `蒸馏器: 运行中`、`锁: 81048`、`caffeinate: 81046`。

**做法**：macOS 的后台启动模板固定为 `nohup CMD >> log 2>&1 < /dev/null &`（要防睡眠再套 `caffeinate -i -w <脚本 pid>`）；`setsid`/`disown` 这类 Linux 习惯不要直接移植。启动后必须用 `pgrep` + 锁文件 + 留档文件大小**三件套**验收，不能只看启动命令有没有报错。

**边界**：这是"启动失败"而不是"进程崩了"——失败信号是留档文件极小且进程不存在；若留档有内容说明至少跨过了启动这一步，应换查别的原因。
