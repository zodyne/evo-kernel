---
id: macos-crash-dialog-dialogtype-none
type: lesson
status: candidate
scope: global
domain: macos
tags: [macos, crashreporter, dialog, defaults, crash-report, harness-scope]
triggers:
  - "macOS 反复弹「xxx quit unexpectedly」崩溃弹窗，想静音又不想丢崩溃日志"
  - "跑脚本/探针时崩溃弹窗不停打断，想关掉提示"
  - "想判断某个 macOS 设置是用户级系统偏好还是 per-harness 配置（pi / Claude Code 要不要各写一份）"
  - "要给崩溃弹窗静音，但不确定怎么回滚、会不会连 .ips 日志一起没了"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a90b-fa1b-769f-b2a4-6c411d10843a
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: []
---

# macOS 崩溃弹窗开关是用户级偏好 `com.apple.CrashReporter DialogType`，与 harness 无关

## 主张

macOS 上「Python quit unexpectedly」这类崩溃弹窗由系统守护进程（`ReportCrash` /
`CrashReporterSupportHelper`）显示，开关是**用户级系统偏好**：

```bash
defaults write  com.apple.CrashReporter DialogType none   # 静音
defaults read   com.apple.CrashReporter DialogType        # 读回确认 == none
defaults delete com.apple.CrashReporter DialogType        # 回滚
```

设成 `none` 后崩溃**照旧**写 `~/Library/Logs/DiagnosticReports/*.ips`，只是不再弹窗。
生效范围与 harness 无关：消费这条偏好的是系统守护进程，pi 起的、Claude Code 起的、手敲的进程都算
——所以「别弹窗」不该去 pi 的 `AGENTS.md` / Claude Code 的 `CLAUDE.md` 各写一份。

## 为什么

弹窗不是 Python 异常提示、也不是 harness 行为：进程收到致命信号后由系统崩溃报告链路处理。
崩溃报告里的 `responsibleProc` 是启动它的终端（本机为 ghostty），与是哪个 agent 写的脚本无关。

## 证据（2026-09-16 会话内命令与结果）

- `defaults write com.apple.CrashReporter DialogType none && defaults read com.apple.CrashReporter DialogType`
  → 读回 `none`。
- `defaults read com.apple.CrashReporter` → `{ DialogType = none; patternMatchServiceCrashes.bootUUID = ... }`，
  落在用户域 `~/Library/Preferences/com.apple.CrashReporter.plist`。
- `strings -a /System/Library/CoreServices/ReportCrash | grep -i dialogtype` 在 macOS 15.7.8 上命中 `DialogType`。
- `ps` 显示 `ReportCrash` / `CrashReporterSupportHelper` / `CoreServicesUIAgent` 常驻；
  当天 21 份崩溃报告的 `responsibleProc` 全是 ghostty（终端），弹窗链路不经过 pi。
- `killall ReportCrash` 无效（系统守护进程、TERM 杀不掉），但它们按次经 cfprefsd 读偏好，
  **不需要重启**才生效。

## 反例 / 边界

- **弹窗是否真的不再出现，本会话没有目视验证**：Ghostty 未获屏幕录制权限，`screencapture -x` 只拍到壁纸，
  所以这一条留给了用户下次崩溃时自己看。引用本条目时不要声称「静音已实测生效」。
- `sudo` 启动的进程是否同样静音未验证（偏好写在用户域）。
- 静音只是遮症状：进程确实收到了致命信号，事故仍要按 `.ips` 查因；改成 `none` 也意味着以后**所有**程序的
  崩溃都不再提醒（含自己开发的 GUI 程序）。
