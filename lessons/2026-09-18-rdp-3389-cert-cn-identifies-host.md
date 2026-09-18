---
id: rdp-3389-cert-cn-identifies-host
type: lesson
status: candidate
scope: global
domain: macos-networking
tags: [rdp, tls, certificate, host-identification, lan]
triggers:
  - "只有一个内网 IP，想知道它到底是哪台 Windows 机器"
  - "DNS 短名、NetBIOS 名都查不到主机身份，需要换一种办法确认"
  - "3389 开着但书签里的名字和这台机器对不上（失败信号：疑似机器被改名/重装）"
  - "写脚本要按 IP 探测主机身份，不想依赖 SMB/NetBIOS"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b253-5635-7373-a922-2b2ad50891db
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

一句话主张：在 RDP 端口 3389 上先发一个 X.224 Connection Request（协商请求里勾选纯 TLS 0x01），再在同一 TCP 连接上做 TLS 握手，读服务端证书的 CN，就能从 IP 反查出这台 Windows 的机器名——比 SMB/NetBIOS 探测更可靠，因为 3389 通常开着而 SMB 常被防火墙拦。

**为什么**：Windows 的 RDP 服务端用机器名签自签证书，CN 通常就是机器名；而内网短名解析（DNS/NetBIOS/mDNS）在 macOS 侧经常整条链路都不可用，SMB 探测又会因 445 被拦而超时，于是「证书 CN」成了少数不依赖名字解析的身份来源。

**证据**（会话 01a0b253 命令↔结果切片，两个探针脚本）：
- X.224 探测：`/tmp/rdp_probe.py` → `<lan-host>:3389  响应 19 字节: 030000130ed00003123400021f080002000000  → TPKT/X.224 正常, 协商类型=2 (2=RDP协商响应), 选定协议位=0x2`（服务端在协议层应答，端口不是假开）。
- 取证：`/tmp/rdp_cert.py` → `协商响应: 030000130ed00003123400021f080001000000 TLS 版本: TLSv1.2 证书已保存，解码如下：--- 证书主题/颁发者 --- subject= /CN=DESKTOP-38TIGL1 i...`。
- 对照：同一批主机用 NetBIOS 查询 `smbutil status -a <ip>`，部分主机直接 `Operation timed out: unable to get status from <lan-host> usin...`，说明 SMB 通道拿身份不可靠。

**边界**：证书 CN 是 RDP 服务端自签证书里的名字，若机器被改名过、或证书是复制的模板，CN 会与当前计算机名不一致，只能当强线索不能当唯一证据；握手要在同一连接上先做 X.224 协商再 TLS（直接对 3389 裸做 TLS 会被拒），这一步用 python socket+ssl 最省事。本会话里 .201 的证书 CN 是 `DESKTOP-38TIGL1`，与书签里的旧名（见 `rdp-bookmark-stale-lan-hostname-use-ip`）不是同一个字符串，正好解释了那个名字为什么解析不了。
