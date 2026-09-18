---
id: mau-disable-autocheck-howtocheck-manual
type: lesson
status: candidate
scope: global
domain: macos-apps
tags: [microsoft-autoupdate, mau, macos-defaults, auto-update]
triggers:
  - "要关掉 Microsoft AutoUpdate 的自动检查更新（Office / Windows App / Edge 等微软 app）"
  - "非商店版微软 app 在后台自动下载更新，想改成只有手动点才更新"
  - "改了 /Library/Preferences/com.microsoft.autoupdate2 或系统域设置不生效（失败信号）"
  - "想确认某台 Mac 的微软 app 更新通道当前是自动还是手动"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b253-5635-7373-a922-2b2ad50891db
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

一句话主张：关掉 Microsoft AutoUpdate 自动检查的落点是用户域 `com.microsoft.autoupdate2` 的 `HowToCheck` 键：`defaults write com.microsoft.autoupdate2 HowToCheck -string Manual`，读回从 `AutomaticCheck` 变成 `Manual`——用户域优先于 `/Library/Preferences` 里的系统域设置，所以不必动 root 的系统偏好。

**为什么**：MAU 的更新策略键（`HowToCheck` / `AutomaticCheck` / `AutomaticDownload` / `ChannelName` 等）同时存在于系统域（`/Library/Preferences/com.microsoft.autoupdate2`，由 MAU 安装时写入、含 `ApplicationsSystem` 受管应用清单）和用户域；用户域的 `defaults` 优先级更高，写用户域即可覆盖系统策略且无需 sudo、影响面只限当前用户。

**证据**（会话 01a0b253 命令↔结果切片）：
- 安装面：`ls "/Library/Application Support/Microsoft/MAU2.0/"` → 目录存在（MAU 已装）。
- 可用键：在 MAU 二进制（`.../Microsoft AutoUpdate.app/Contents/MacOS/Microsoft AutoUpdate`）里 strings 出的偏好键为 `Applications AutomaticCheck AutomaticDownload ChannelName HowToCheck Manual`——`HowToCheck` 与值 `Manual` 都是 MAU 自己认识的。
- 改前：`defaults read com.microsoft.autoupdate2 HowToCheck` → `AutomaticCheck`；写入后读回 → `Manual`（切片标注「用户域，优先级高于 /Library」）。
- 同一命令还打印了受管应用清单，确认这套设置覆盖的就是 `"/Applications/Windows App.app"` 与 Microsoft AutoUpdate 这两个 app（即关闭自动检查的目标确实是用户装的那个 RDP 客户端）。

**边界**：切片只到「写入并读回生效」，没有等一个更新周期验证「确实不再自动检查/下载」（`AutomaticDownload` 等其余键本会话没改）；要更彻底还得看 `AutomaticCheck`/`AutomaticDownload`/`ChannelName` 各自取值。若机器由 MDM 或系统域强制策略下发，用户域覆盖是否仍成立需要另测；回滚方式是 `defaults delete com.microsoft.autoupdate2 HowToCheck`。相关：判断某 app 是否归 MAU 管（而非 App Store 管）见 `macos-app-source-masreceipt-check`。
