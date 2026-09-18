---
id: windows-ssh-curl-research-via-mac-proxy-env
type: lesson
status: candidate
scope: global
domain: network
tags: [research, github-api, proxy, curl, version-verification]
triggers:
  - "要查 GitHub 仓库某版本有没有某子命令/某实现，但不想到处 clone"
  - "担心本地安装版本与官方最新文档不一致，调研结论要锚定具体 tag"
  - "查 sing-box / mihomo 这类多版本快速演进的工具的配置或能力"
  - "文档页里搜不到某关键词，想确认是该版本真没有还是文档没写"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0affb-58dd-73b1-bdd8-c2ca9d44ed64
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [github-api-tree-inspect-before-clone]
---

调研多版本快速演进的代理工具（sing-box/mihomo 类）时，不 clone、直接经代理用 GitHub raw/API 按 tag 拉源码与文档页来回答「某版本有没有某能力」，且版本结论要锚定本机实测版本号而非官方文档默认展示的最新版。

为什么：确认 sing-box 有没有 Windows service 子命令时，官方文档页搜不到答案；改为拉 `api.github.com` 的 `cmd/sing-box` 目录清单、`raw.githubusercontent.com` 按 tag 对照 v1.11.0/v1.9.0 旧版本源码、核对 release 资产精确文件名，全部经 `ALL_PROXY=socks5h://localhost:1080` 完成，零 clone 得出「新旧版本都无 service 子命令」的硬结论。能力判断锚定 `sing-box version`（1.13.19）实测输出，文档页 TUN 描述与 wintun 关键词缺失也用同法交叉核对，避免了拿最新文档套旧版本或反之的错配。

边界：适用于「读代码/读文档下结论」类调研；需要实际运行验证的行为（如 check 报错）仍须本机真实执行。raw/API 走代理在境内网络是前提，直连 GitHub 不可达时此路不通。

证据：会话内连续多次 `curl -s -m 25`（带 ALL_PROXY）拉 GitHub API/releases/raw 源码，输出含 `v1.11.0 service 相关: 无`、`sing-box version 1.13.19`、release 资产名 `sing-box-1.13.19-windows-386-...zip`；mihomo ss2022 支持同样经 `adapter/outbound/shadowsocks.go` 源码拉取确认。
