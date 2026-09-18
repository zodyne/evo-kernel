---
id: steam-appid-platform-support-check
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [steam, api, cross-platform, macos, research]
triggers:
  - "要判断某个游戏/软件有没有 macOS 或 Linux 版，但不想下载安装包试"
  - "调研开源游戏的跨平台可用性，要 mac/linux/win 三个可判真的布尔值"
  - "手上有 Steam appid，想批量查一批作品的平台支持再筛选"
  - "抓官网首页/发行说明也判不出平台支持，只能捞到零散自然语言句子（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad13-1d64-710a-b61a-fd28b9b67884
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [community-research-rss-api-first]
---

判断一个游戏有没有 macOS / Linux 版，最省事的办法是**按 Steam appid 查商店元数据接口，读返回里的 `platforms` 三布尔字段（mac / linux / win）**：`for a in "<appid>:<名字>"` 循环一次就能把一批作品的平台支持跑成结构化输出，比抓官网首页再 `sed` 去标签 grep 可靠得多。

为什么：同一会话里对 Zero-K、Mindustry 的官网做去标签 grep，只能捞到「Linux users with ATI graphics」「Google Play / F-Droid / App Store」这类零散句子，判不出 mac 版有无；改用 appid 批量查询后，输出直接是 `-- Zero-K (334920) platforms: mac=false linux=true win=true`、`-- Mindustry (1127400) platforms: mac=true ...`——单个布尔值即可判真。

边界：只对在 Steam 上有条目的作品有效（0 A.D. 这类未上架的作品查不到，得回落到官网/自建 forge）；`platforms` 是商店标注，不代表官方发行包在该平台上一定可下载可用（例如本会话最终去下载的是 Cataclysm-DDA 官方 DMG，与 Steam 无关）。

证据：切片保留了该批查询的命令首行 `for a in "334920:Zero-K" "1127400:Mindustry" "1241950:Warzone2100" "1604030:OpenTTD"`（slice 只截命令前 150 字符，端点 URL 未落在切片内），结果行给出 `platforms: mac=false linux=true win=true`（Zero-K，334920）、`platforms: mac=true ...`（Mindustry，1127400）。
