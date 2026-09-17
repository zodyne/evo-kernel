---
id: homebrew-ghcr-bottle-unreachable-cn
type: fact
status: validated
scope: global
domain: networking
tags: [homebrew, ghcr, bottle, 境内网络, 镜像, 代理, 实测]
triggers:
  - Homebrew bottle 源 ghcr.io 直连/镜像/加速/本地 socks 代理全部不可达
  - brew install 无限卡下载、速度 ≤150B/s
  - 判定前是否先 curl 实测 ghcr blob 速度
  - 卡死时该放弃 brew 改官方分发还是继续换镜像
  - 境内装 brew 包卡在 ghcr.io
created: 2026-09-08
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-08-04-56-59-333-x0oi
last_verified: 2026-09-08
superseded_by: null
schema_version: 1
related: []
---

# 【网络/境内】Homebrew bottle 源 ghcr.io 及各种镜像/加速/本地代理全部不可达

【网络/境内】Homebrew bottle 源 ghcr.io 直连/南大镜像ghcr.nju.edu.cn/公共加速gh-proxy.com+ghfast.top/本地socks代理全部不可达(实测≤150B/s,brew install无限卡下载);判定前先curl实测ghcr blob速度;卡死则放弃brew改官方分发或源码构建,勿死磕
