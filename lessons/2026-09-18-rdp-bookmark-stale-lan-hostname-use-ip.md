---
id: rdp-bookmark-stale-lan-hostname-use-ip
type: lesson
status: candidate
scope: global
domain: macos-networking
tags: [rdp, windows-app, lan-hostname, netbios, dns-resolution]
triggers:
  - "Windows App / Microsoft Remote Desktop 连不上某台内网机器，但该 IP 能 ping 通"
  - "RDP 客户端报连不上，而 nc -vz <ip> 3389 返回 succeeded（失败信号：网络层没问题）"
  - "远程桌面书签里的主机名是内网短名/机器名，dscacheutil 或 ping 报 cannot resolve"
  - "目标机换名/重装后旧书签失效，不确定该查 DNS 还是直接用 IP"
  - "要把内网机器填进 RDP 书签或脚本，犹豫用短名还是 IP"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b253-5635-7373-a922-2b2ad50891db
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

一句话主张：RDP 连不上而目标 IP 的 3389 端口明明可达时，问题在客户端保存的主机名——书签里存的是已解析不了的内网短名（本会话 `ZHOSTNAME = tangfuqiang`），把书签主机名换成 IP 即可绕开解析；排查顺序应是「先 nc 端口确认目标可达 → 再查书签主机名能否解析」，而不是先去查网络。

**为什么**：Windows App 按书签里的主机名字符串做解析，解析失败根本走不到 TCP 连接阶段，表象和「网络不通」一样；而同一台机器的 IP 层（ICMP + 3389 握手）完全正常，两条证据一对比就能把故障锁在名字解析这一层。本会话里该名字在 macOS 侧全链路解析失败：`ping: cannot resolve tangfuqiang: Unknown host`、`/etc/hosts` 与 `~/.ssh` 等配置里搜不到、`.local`/mDNS 无结果、NetBIOS 查询 `smbutil: unable to resolve tangfuqiang: No route to host`、路由器 `dig` 返回 SERVFAIL、办公室 dnsmasq(<lan-host>) 对同类内网名一律 NXDOMAIN。

**证据**（均来自会话 01a0b253 的命令↔结果切片）：
- `ping -c 3 -W 1000 <lan-host>` → `64 bytes from <lan-host>: icmp_seq=0`（IP 可达）。
- `nc -vz -G 3 <lan-host> 3389` → `Connection to <lan-host> port 3389 [tcp/ms-wbt-server] succeeded! rc=0`。
- 书签条目：`Z_PK = 1  ZFRIENDLYNAME =  ZHOSTNAME = tangfuqiang`；另一条 dump 显示 `host = 'tangfuqiang' conn_count = 0  last_conn = NULL`（从没连上过）。
- `dscacheutil -q host -a name tangfuqiang` → 无输出；`ping tangfuqiang` → `cannot resolve tangfuqiang: Unknown host`。
- 改书签为 IP 后重启 app：`条目确认未被回写 === ZHOSTNAME = <lan-host>`（改动持久，见 `rdp-bookmark-sqlite-edit-quit-app-first`）。

**边界**：切片只证明「名字解析不了 + IP 层可达 + 书签已改成 IP 并持久化」，没有直接记录改完后一次成功 RDP 会话的日志，所以别把「已恢复远程」写成实锤；`conn_count = 0 / last_conn = NULL` 说明该条目从未成功连过，若历史上有过成功连接，要另找机器被改名的时点。判定书签里该填什么名字前，仍用 `dscacheutil` + 逐台 DNS `dig` 验证，别假定内网一定解析短名（本办公网就是这么不解析，参见 facts `office-lan-mac-gateway-nginx-dnsmasq-resolver`）。想知道这个 IP 到底是哪台机器，用 `rdp-3389-cert-cn-identifies-host` 的办法取证书 CN。
