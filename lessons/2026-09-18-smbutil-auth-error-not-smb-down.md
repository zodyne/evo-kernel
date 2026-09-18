---
id: smbutil-auth-error-not-smb-down
type: lesson
status: candidate
scope: global
domain: macos-networking
tags: [smb, smbutil, netbios, port-445, lan-probing]
triggers:
  - "smbutil view -N 报 server rejected the authentication，想判断对端 445 后面到底有没有 SMB 服务"
  - "macOS 无凭据访问内网 Windows 共享失败：该换凭据，还是服务根本不在（失败信号：把所有认证错误当成服务不可用）"
  - "只知道内网 IP，想借 445 通道确认它是 Windows 并拿到 NetBIOS 名"
  - "手写 SMB2 NEGOTIATE（fe534d42）探 445，想确认什么样的应答算『服务活着』"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0aa46-842a-765e-9e51-00867512a904
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

一句话主张：macOS 上 `smbutil view -N //<ip>` 返回 `server rejected the authentication` 只说明**匿名 SMB 会话**被拒（或用户/域写法不对），不能据此推断 445 没开、或后端不是 SMB 服务；要判定服务是否活着，直接往 445 发一个 SMB2 NEGOTIATE（magic `fe534d42` + 64 字节头 + dialect 列表），能收到 SMB2 应答就说明服务在——本会话收到 76 字节应答，脚本解析为 `SMB2 cmd=0x0000 status=0xc000000d`。

**为什么**：`smbutil view` 走的是「建立 SMB 会话 → 列共享」，链路上任何一步被拒都只回报 authentication error，它无法区分「服务不在」与「拒绝匿名」；而裸 NEGOTIATE 不需要任何凭据，服务端必须回应协商结果，因此是判断 445 后面究竟是什么的最薄探测。

**证据**（会话 01a0aa46 命令↔结果切片，目标 <lan-host>）：
- 端口层：并行 `nc -z -G 1` 扫描 13 个常见端口只报 `OPEN  445`（`ping` 正常、`arp -n` 显示 MAC `70:32:17:4a:ae:4d`）。
- 名字通道可用：`smbutil status -a <lan-host>` → NetBIOS 表 `X13 0x00 UNIQUE [Workstation Service]` + `WORKGROUP …`。
- 会话通道被拒：`timeout 10 smbutil view -N //<lan-host>` → `smbutil: server rejected the authentication: Authentication error`；换 `//orclycan:1028@`、`//WORKGROUP;orclycan:1028@`、`//X13;orclycan:1028@` 三种写法被同样拒绝（该命令末尾 `echo "exit=$?"` 打印的是管道里 `head` 的状态、恒为 0，不能当作 smbutil 的成败判据）。
- 裸协商拿到真实应答：python 标准库手写 SMB2 NEGOTIATE（dialects `0x0202/0x0210/0x0300/0x0302/0x0311`）→ `原始响应长度: 76`，`hex: 00000048fe534d42400000000d0000c000000100…`，脚本自解析 `SMB2 cmd=0x0000 status=0xc000000d`。
- 对照：同一会话早先照 SMB1 报文（magic `ff534d42`）探同一端口 → `错误: timed out`（切片无法区分是 SMB1 被禁用还是报文本身有问题，只作为「照抄 SMB1 格式探不通」的观察，不作结论）。

**边界**：`status=0xc000000d`（STATUS_INVALID_PARAMETER）说明协商体没被接受，只能证明「有个活的 SMB2 栈在应答」，不能证明协商成功、更不能证明认证能过；本会话最终也没连上（共享列不出）。`smbutil status -a` 的 NetBIOS 查询与 `smbutil view` 的 SMB 会话是两条独立通道——本会话正是前者成功、后者被拒，别用其中一条的结果去否定另一条。若手上已有凭据，优先用官方路径（`smbutil view //user:pw@ip`）而不是手搓报文。
