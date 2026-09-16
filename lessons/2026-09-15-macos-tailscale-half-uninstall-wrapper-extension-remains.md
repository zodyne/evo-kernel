---
id: macos-tailscale-half-uninstall-wrapper-extension-remains
type: lesson
status: candidate
scope: global
domain: macos-networking
tags: [tailscale, macos, uninstall, network-extension, vpn]
triggers:
  - "macOS 卸载 Tailscale 后 tailscale 命令仍报错"
  - "tailscale: line 2: /Applications/Tailscale.app/Contents/MacOS/Tailscale: No such file or directory（失败信号）"
  - "删了 Tailscale.app 但 tailnet 还是连不上，怀疑有残留"
  - "Mac 上 Tailscale 卸载后残留网络扩展 / 系统扩展"
  - "tailscale status 报 wrapper 找不到二进制"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09fda-34ee-75f1-8fc4-18b82cc88983
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
---
一句话主张：macOS 上 Tailscale 会"半卸载"——`/Applications/Tailscale.app` 已删，但 `/usr/local/bin/tailscale` 这个 wrapper 还留着、指向已删除的二进制。此时 `tailscale` 命令报 `line 2: /Applications/Tailscale.app/Contents/MacOS/Tailscale: No such file or directory`，这个报错本身就是要你检查"wrapper 残留"的信号，也是 tailnet 连不上的根因。

为什么：删 app 不会自动清掉 wrapper 脚本和网络系统扩展；wrapper 的第一行（shebang/exec 指向）仍指向 `/Applications/Tailscale.app/Contents/MacOS/Tailscale`，二进制没了，于是任何 `tailscale` 子命令都在 `line 2` 直接 "No such file or directory"。排查时容易被"命令找不到"的表象带偏去怀疑 PATH，实际是残留物在捣乱。

边界/证据链接（均来自会话 01a09fda 的命令 ↔ 结果切片）：
- `tailscale status` → `/usr/local/bin/tailscale: line 2: /Applications/Tailscale.app/Contents/MacOS/Tailscale: No such file or directory`，命令级实测，wrapper 指向已删二进制这一半证据充分。
- 末条 assistant 明确判定"Mac 上 Tailscale 是半卸载状态 —— app 删了，但网络扩展还留着（`io.tailscale.ipn.macsys.network-extension [activated waiting for user]`），`/usr/local/bin/tailscale` wrapper 也残留"；但网络扩展残留这一半来自诊断结论，切片中未见其原始命令输出，引用时对扩展残留侧留一分保守。
- 会话是排查 pi API 网关晚间变慢时发现"本机已无 tailnet 连接"，由这条 wrapper 报错顺藤摸出的半卸载状态。
