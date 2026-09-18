---
id: rdp-bookmark-sqlite-edit-quit-app-first
type: lesson
status: candidate
scope: global
domain: macos-apps
tags: [rdp, windows-app, sqlite, zbookmarkentity, app-container]
triggers:
  - "要改 Windows App / Microsoft Remote Desktop 保存的 PC 书签（主机名/地址），但没有 GUI 或不想点界面"
  - "想直接编辑 com.microsoft.rdc.application-data.sqlite 里的 ZBOOKMARKENTITY"
  - "改完书签重启 app 发现改动被回写覆盖（失败信号）"
  - "agent/无人值守会话里要批量修改或备份 RDP 书签条目"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b253-5635-7373-a922-2b2ad50891db
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

一句话主张：Windows App（bundle id `com.microsoft.rdc.macos`）的书签存在 `~/Library/Containers/com.microsoft.rdc.macos/Data/Library/Application Support/com.microsoft.rdc.macos/com.microsoft.rdc.application-data.sqlite` 的 `ZBOOKMARKENTITY` 表（主机名字段 `ZHOSTNAME`），可以直接用 sqlite3 改；但**必须先把 app 退干净、并备份该 sqlite，改完再启动**——本会话按「`osascript -e 'quit app "Windows App"'` → 备份 → 改 → `open -a` 重启」的顺序做，重启后条目值保留。

**为什么**：容器内 app 的偏好/书签是 app 自己持有的 SQLite，运行中的进程会把内存态回写覆盖外部改动；先退出再改才能让改动成为重启后读到的初始状态。书签表结构简单（`Z_PK / ZFRIENDLYNAME / ZHOSTNAME / ZGATEWAY / ZRDPSTRING`，另有一张 `ZBOOKMARKENTITY` 元数据带 `Z_OPT` 版本号），读改写不需要碰 GUI。

**证据**（会话 01a0b253 命令↔结果切片）：
- 读：`sqlite3 <com.microsoft.rdc.application-data.sqlite>` → `ZALTFEEDSENTITY / ZLICENSEENTITY / ZBOOKMARKENTITY / ZPINNEDRESOURCESENTITY`；条目 dump → `Z_PK = 1  ZHOSTNAME = tangfuqiang`；`Z_NAME = BookmarkEntity`（库里只有这一条书签）。
- 退出+备份：`pgrep -f "Windows App.app/Contents/MacOS/Windows App"` → `82665`；`osascript -e 'quit app "Windows App"'` → `已退出（等待 2s）`；`备份完成 -rw-r--r--@ 1 zodyne wheel 163840 ... /tmp/rdp-appdat...`。
- 改前版本号：`Z_OPT = 3`（说明该条目此前被 app 改过 3 次，不是全新条目）。
- 改后重启验证：`open -a "Windows App"` → 进程 `7837 (已启动)`；`条目确认未被回写 === ZHOSTNAME = <lan-host>`。

**边界**：这是绕过 GUI 的直接改库，写入前务必备份 sqlite；app 未退出时改会不会被覆盖，切片里没有对照实验（只验证了「退出后改 → 重启保留」这一条路径），所以别把「运行中改必被覆盖」当成实测结论。重启后 app 可能新写日志到 `.../Data/Library/Logs/Windows App/`，可用来复核条目是否被读对。容器路径里的空格要引号包好（切片命令里出现过 `Application\ Support`）。
