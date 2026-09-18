---
id: macos-app-source-masreceipt-check
type: fact
status: validated
scope: global
domain: macos-apps
tags: [macos, app-install-source, masreceipt, auto-update]
triggers:
  - "想知道某个 mac app 是 App Store 装的还是官网 pkg/dmg 装的"
  - "要为某 app 决定更新通道：走 App Store 还是 Microsoft AutoUpdate / 官网更新器"
  - "Contents/_MASReceipt 不存在，怀疑装的是绿色版或被改过（失败信号）"
  - "排查某个 app 的自动更新行为，先要确认它的安装来源"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b253-5635-7373-a922-2b2ad50891db
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

一句话主张：判定一个 mac app 是不是 App Store 装的，看 `Contents/_MASReceipt` 目录是否存在即可——`ls -la "/Applications/<App>.app/Contents/_MASReceipt/"` 报 `No such file or directory` 就是非商店版（官网下载的 pkg/dmg 安装），它的更新走厂商自己的更新器而不是 App Store。

**为什么**：App Store 安装时会给 bundle 写入 `_MASReceipt` 收据目录，官网分发（Developer ID 签名 + 公证）不会写；这个差异直接决定「该去 App Store 更新，还是在 `defaults`/MAU 层面关掉厂商更新器」——本会话就是要关掉非商店版的自动更新，所以必须先确认它不是商店版。

**证据**（会话 01a0b253 命令↔结果切片）：
- `ls -la "$A/Contents/_MASReceipt/"`（A=`/Applications/Windows App.app`）→ `ls: /Applications/Windows App.app/Contents/_MASReceipt/: No such file or`。
- 会话末条结论同向：`Windows App 是**微软官网下载版**（Developer ID Application: Microsoft Corpor...`。
- 交叉印证：系统里存在 Microsoft AutoUpdate 且其受管应用清单含 `"/Applications/Windows App.app"`（非商店 app 才由 MAU 管）。

**边界**：`_MASReceipt` 缺失只能证明「不是 App Store 直接安装」，不等于签名合法或来源可信——来源与签名要另看 `codesign -dv`/`spctl -a`；个别第三方工具搬移 app 也可能丢掉收据。本会话只用它区分更新通道，没有做签名核验。
