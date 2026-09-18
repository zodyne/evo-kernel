---
id: github-wrong-owner-path-silent-not-found
type: lesson
status: validated
scope: global
domain: research-methodology
tags: [github, api, release, silent-failure, research]
triggers:
  - "curl GitHub 的 releases.atom / /releases 页拿不到东西，正文只有 Not Found 或一片空白"
  - "按项目名猜 GitHub owner/repo 路径做批量调研（形如 Cataclysm-DDA/Cataclysm-DDA）"
  - "releases API 返回的 tag/资源列表为空，准备下结论『这个项目没有 release』（失败信号）"
  - "同一批仓库里有的拿到数据有的全空，要判断是仓库路径写错还是真没发布"
  - "调研一个老项目的最新版本/下载资产，不确定官方仓库到底挂在哪个 owner 下"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad13-1d64-710a-b61a-fd28b9b67884
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [github-api-tree-inspect-before-clone, curl-max-time-timeout-empty-looks-like-no-match]
---

GitHub 项目的 owner 改名/迁移后，**用旧路径（或按项目名生猜出来的路径）打 API 不会报错**：releases API 给空字段、网页 grep 给空命中、`releases.atom` 正文只回三个字 `Not Found`（HTTP 语义上是 404 页面，但 curl 退出码为 0）。管道下游的 `grep`/`jq` 会把这种静默空结果当「该项目没有 release / 没有资产」处理，结论直接是错的。

为什么：调研 Cataclysm-DDA 时按项目名猜出 `Cataclysm-DDA/Cataclysm-DDA`，连续三次取证全是空——取最新 release 资源文件名时 `tag` 为空、`/releases` 页宽松 grep 无输出、`releases.atom` 前 40 行原文就是 `Not Found`。换成真正的 canonical owner `CleverRaven/Cataclysm-DDA` 后，**同一端点**立即返回 `Release notes from Cataclysm-DDA ...`，并列出 `0.I.tar.gz / 0.I.zip / cdda-osx-terminal-only-universal-2026-06-06-1535.dmg` 等资产。

边界与判据：失败形态随端点而异（API 空字段 / 页面空 grep / atom 的 `Not Found`），但都不带 non-zero 退出码，所以要靠「换 canonical owner 后复测同一端点，结果从空变有数据」来确认，而不是靠退出码。`releases.atom` 是纯文本、最省事的第一探针；owner 的权威来源是项目官网/项目页给出的仓库链接，不是项目名本身。

证据：切片中 `Cataclysm-DDA/Cataclysm-DDA` 三次失败（`tag:` 为空、宽松 grep 空、`releases.atom` → `Not Found`），随后 `CleverRaven/Cataclysm-DDA/releases.atom` → `Release notes from Cataclysm-DDA 2026-09-17T01:58:53Z`，且同 owner 下 `/releases/download/0.I/...` 资产名可枚举。
