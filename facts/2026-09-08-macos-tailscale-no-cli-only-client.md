---
id: macos-tailscale-no-cli-only-client
type: fact
status: validated
scope: global
domain: macos-networking
tags: [Tailscale, macOS, CLI, Homebrew, 安装包, CDN]
triggers:
  - macOS 上想找 Tailscale 纯 CLI 客户端
  - Tailscale 官方 macOS 分发包有哪些形态
  - 想用 Homebrew 装 tailscale + tailscaled
  - pkgs.tailscale.com 的 macOS 包命名是什么
  - Linux 式 tailscale_<ver>_darwin_arm64.tgz 在 macOS 上 404
created: 2026-09-08
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-08-04-56-59-336-2jdb
last_verified: 2026-09-08
superseded_by: null
schema_version: 1
related: [macos-tailscale-half-uninstall-wrapper-extension-remains]
---

# 【Tailscale/macOS】官方无 CLI-only 客户端

【Tailscale/macOS】官方无CLI-only客户端,仅App Store版与Standalone(Tailscale.app)两种;真纯CLI只有Homebrew core formula tailscale(tailscale+tailscaled,sudo brew services start);pkgs.tailscale.com的macOS包命名是Tailscale-<ver>-macos.pkg/.zip,Linux式tailscale_<ver>_darwin_arm64.tgz对macOS返回404;GitHub release资产为0(二进制全走自家CDN)
