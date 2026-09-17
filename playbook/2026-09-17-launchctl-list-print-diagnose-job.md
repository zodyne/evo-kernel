---
id: launchctl-list-print-diagnose-job
type: lesson
status: validated
scope: global
domain: launchd
tags: [launchd, launchctl, 诊断, 定时任务, macos]
triggers:
  - "想确认某个 launchd job 是否已注册、上次退出码是多少"
  - "launchd 定时任务到点没反应，先确认它是否还在 launchctl 里"
  - "查一个 job 的当前 state / 最近退出 / program / plist 路径"
  - "怀疑 plist 里写的调度时间或命令和实际跑的不一致"
  - "排查 launchd 任务是否触发，不知道该看哪个命令"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad8d-d7a1-764c-a77e-5170e29d623f
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [launchd-log-utc-timezone-trigger-check, launchd-silent-output-disk-only]
---
验证 launchd job 的注册状态、最近退出码、当前 state 与调度配置，按顺序用三条命令即可定位：`launchctl list | grep -i <label>`（是否注册 + 最近 exit code）、`launchctl print gui/$(id -u)/<label>`（state/runs/last exit/path/program）、`cat ~/Library/LaunchAgents/<label>.plist`（schedule + 实际命令）。

本轮"检查 evo 是不是 14:30 触发"正是靠这三条直接定位：`launchctl list` 输出 `-\t0\tcom.evo.distill`（已注册、上次退出码 0），`launchctl print` 输出 `state = not running` + `path = /Users/zodyne/Library/LaunchAgents/com.evo.distill.plist`，`cat plist` 读到调度时间与兜底清理命令。

边界：`launchctl list` 的 exit code 列只反映"最近一次"退出，不能据此判断历史多次运行是否都成功，历史运行记录要看落盘日志（注意日志时间戳可能是 UTC）。`launchctl print` 需带 `gui/$(id -u)/` 前缀才指到当前登录会话的 GUI 域。
