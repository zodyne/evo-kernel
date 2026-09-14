---
id: macos-dual-nic-intranet-subnet-needs-per-service-route
type: lesson
status: validated
scope: global
domain: macos-network
tags: [macos, networksetup, routing, dual-nic, usb-ethernet, wifi, intranet, additional-routes, sudo, osascript, troubleshooting]
triggers:
  - "Mac 同时连 Wi-Fi 和 USB 有线，有线那边的某个内网地址/网段 ping 不通"
  - "有线网卡链路正常、拿到了 DHCP 地址，但访问内网另一个子网 100% 丢包（失败信号）"
  - "route -n get <目标> 显示走 en0/Wi-Fi 而不是有线网卡（失败信号）"
  - "想让某个内网网段走有线、其余流量继续走 Wi-Fi，且不改 Wi-Fi 任何设置"
  - "Claude Code / 非终端 shell 里 sudo 报 a terminal is required to read the password"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:dbbe0909-f982-4244-a443-02a60b555c0b
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: []
---
# Mac 双网卡下"有线那边的内网子网不通"多半是默认路由走了 Wi-Fi：给有线服务加一条 networksetup 附加路由，不动 Wi-Fi

## 主张
Mac 同时接 Wi-Fi（服务顺序第一）和 USB 有线网卡（本机是 AX88179A = en5）时，有线只会自动拥有**它自己 DHCP 网段**的直连路由；办公网里位于有线网关**后面**的其它子网（DHCP 下发的 DNS 服务器就住在那个子网，是最明显的线索）不会自动可达——`route -n get <目标>` 会落到默认路由，即 Wi-Fi 网关，包发错口，100% 丢包。修法是给**有线这个网络服务**加一条持久附加路由：

    sudo networksetup -setadditionalroutes <有线服务名> <目标网段> <掩码> <有线网关>

它绑定在有线服务上（重启、拔插网线自动恢复），Wi-Fi 配置、默认路由、DNS 一律不动。

## 为什么
macOS 的路由来自各网络服务的 DHCP 租约：每个服务只贡献"自己网段直连 + 一条默认路由"，默认路由按服务顺序取第一个（这里是 Wi-Fi）。有线网关虽然能把包转发到内网其它子网，但内核不知道，也没人告诉它。三种候选修法里：`sudo route add` 是临时的（重启/重插即丢）；把有线调到服务顺序第一会让**全部**流量（含上网）改走有线网关，副作用大；`-setadditionalroutes` 只影响"目标网段 → 有线网关"这一条，是最小改动。

## 排查步骤（差分定位，一分钟）
1. `networksetup -listnetworkserviceorder` + `ifconfig | grep -E "^[a-z]|inet |status"` —— 确认有线 status: active、有地址，且 Wi-Fi 排在前面。
2. `ipconfig getpacket en5 | grep -E "router|domain_name_server"` —— 有线 DHCP 给的 DNS 若不在有线自己的网段，说明那个网段在有线网关后面、经它可达。
3. `route -n get <目标>` —— interface 显示 en0（Wi-Fi）即为病灶。
4. 差分：`ping -c 3 <目标>`（走默认路由）vs `ping -c 3 -b en5 <目标>`（macOS 的 `-b` 绑定出口网卡）。前者全丢、后者全通 → 只是路由问题，不是链路/对端问题。
5. 修：`networksetup -setadditionalroutes <有线服务名> <网段> <掩码> <有线网关>`；验：`networksetup -getadditionalroutes <有线服务名>`、`route -n get <目标>` 变成 en5、不带 `-b` 的 ping 通、`networksetup -getinfo Wi-Fi` 与 `route -n get default` 原样。

## 证据（本会话命令 ↔ 结果）
- 修前：`ping -c 2 <目标>` → 100% loss；`ping -c 3 -b en5 <目标>` → 3/3，avg 0.73 ms；`route -n get <目标>` → gateway = Wi-Fi 网关，interface en0。
- `ipconfig getpacket en5` → `domain_name_server` 列表第一个地址落在目标子网内（同一子网的 DNS 主机 `ping -b en5` 2/2 通）。
- 修后：`networksetup -getadditionalroutes AX88179A` → 一条 `<网段> <掩码> <有线网关>`；`route -n get <目标>` → interface en5；不绑定接口的 `ping -c 3 <目标>` → 3/3，avg 0.66 ms。
- Wi-Fi 未动：`networksetup -getinfo Wi-Fi` 地址/网关不变，`-getadditionalroutes Wi-Fi` 为空，`route -n get default` 仍是 Wi-Fi 网关 / en0。

## 边界 / 反例
- 服务名是 `networksetup -listallhardwareports` 里的 **Hardware Port 名**（如 `AX88179A`），不是设备名 `en5`。
- 附加路由把有线网关写死了；有线网络的 DHCP 换网段/换网关后要同步改这条，否则目标网段又会掉回默认路由。
- 如果差分测试里 `ping -b en5` 也不通，那就不是本条的问题（对端不在线 / 网关不转发 / ACL），加路由无效。
- 有线拔掉时这条路由随服务下线，目标网段自然回到 Wi-Fi 默认路由——这是设计行为，不是回归。
- 提权：Claude Code 的 Bash 与 `!` 前缀 shell 都没有 TTY，`sudo` 会报 `a terminal is required to read the password`；用 `osascript -e 'do shell script "<命令>" with administrator privileges'` 弹 macOS 图形授权框即可代跑，无需另开终端。

## 失败信号（未来命中即该想起本条）
- 有线灯亮、链路 1000baseT、DHCP 地址正常，但"就是 ping 不通那台内网机器"。
- 第一反应去查对端、查网线、重启网卡，却没先 `route -n get` 看包从哪个口出去。
- 想通过调服务顺序或关 Wi-Fi 来"解决"，结果上网也跟着换了出口。
- 在 Claude Code 里反复让用户 `! sudo …`，每次都被 "a terminal is required" 挡回。
