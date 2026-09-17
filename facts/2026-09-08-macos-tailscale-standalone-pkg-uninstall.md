---
id: macos-tailscale-standalone-pkg-uninstall
type: fact
status: validated
scope: global
domain: macos-networking
tags: [Tailscale, macOS, 卸载, pkgutil, osascript, 授权]
triggers:
  - macOS 卸载 Standalone pkg 版 Tailscale
  - 包 id com.tailscale.ipn.macsys 只装了哪个目录
  - 卸载用 sudo rm -rf app + sudo pkgutil --forget
  - 无 GUI 会话下用 osascript with administrator privileges 代执行 sudo
  - 想确认 Tailscale standalone 是否装了 LaunchDaemon/系统扩展
created: 2026-09-08
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-09-08-04-57-05-457-vht6
last_verified: 2026-09-08
superseded_by: null
schema_version: 1
related: [macos-tailscale-half-uninstall-wrapper-extension-remains]
---

# 【Tailscale/macOS卸载】standalone pkg 只装单一 app 目录，卸载 = 删 app + pkgutil --forget

【Tailscale/macOS卸载】standalone pkg(包id com.tailscale.ipn.macsys)只装/Applications/Tailscale.app单一目录,无LaunchDaemon/系统扩展;卸载=sudo rm -rf app + sudo pkgutil --forget;无GUI会话下可osascript 'do shell script ... with administrator privileges'弹授权框代执行sudo
