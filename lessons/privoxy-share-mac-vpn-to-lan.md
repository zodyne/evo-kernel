---
id: privoxy-share-mac-vpn-to-lan
type: lesson
status: candidate
scope: global
domain: network
tags: [privoxy, vpn, proxy, macos, homebrew, 局域网共享]
triggers:
  - "想让手机/平板等同 Wi-Fi 设备走 Mac 本机的 VPN 出口"
  - "Mac 上只有 VPN 隧道（utun / NordLynx / WireGuard），没有可分享的 HTTP 代理端口"
  - "手机填了 Mac 的手动代理后连不上，怀疑代理只监听 127.0.0.1"
  - "验证代理链路是否真走 VPN：对比 curl -x 代理 与直连的出口 IP"
created: 2026-08-05
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fd1ca-7709-7957-a1e2-e90fb2088e95
last_verified: 2026-08-05
superseded_by: null
schema_version: 1
related: [brew-services-start-not-equal-port-listening]
---

Mac 本机的 VPN 隧道默认只服务本机；要共享给局域网设备，最简路径是 **privoxy 监听 0.0.0.0**：`brew install privoxy` → 把 `/opt/homebrew/etc/privoxy/config` 里 `listen-address 127.0.0.1:8118` 改为 `0.0.0.0:8118` → `brew services start privoxy` → 手机（同一 Wi-Fi）Wi-Fi 设置里填手动代理 `<Mac局域网IP>:8118`。privoxy 出本机的流量自然进入已连接的 VPN 隧道，无需额外路由配置。

前置排查组合（确认没有现成代理、确认 VPN 在线）：`scutil --proxy`（系统代理）、`lsof -iTCP -sTCP:LISTEN | grep -E '7890|1087|1080|8118...'`（常见代理端口）、`scutil --nc list`（VPN 连接状态，`* (Connected)` 标记）、`ipconfig getifaddr en0`（取 Mac 局域网 IP）。

**验证判据**：`curl -x http://<Mac局域网IP>:8118 https://ifconfig.me` 的出口 IP 应与 Mac 直连（走 VPN）的出口 IP 一致——一致即证明链路「设备 → Mac privoxy → VPN 隧道」成立。注意 VPN 可能中途换节点，先后两次直连出口 IP 不同属正常，要同一时间窗内对比。

会话证据：privoxy 改完监听地址后，`curl -x http://192.168.100.104:8118 https://ifconfig.me` 返回 `94.140.8.9`，与同时段 Mac 直连出口 `94.140.8.9` 一致（`scutil --nc list` 显示 NordVPN NordLynx Connected）。

边界：macOS 应用防火墙若开启需放行 privoxy（本次 `socketfilterfw --getglobalstate` 显示 Firewall disabled）；手机必须与 Mac 同网段。
