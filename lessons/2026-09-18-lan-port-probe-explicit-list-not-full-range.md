---
id: lan-port-probe-explicit-list-not-full-range
type: lesson
status: candidate
scope: global
domain: macos-networking
tags: [nc, port-scan, lan, macos, nmap]
triggers:
  - "macOS 上没装 nmap/masscan，却想扫内网主机开了哪些端口"
  - "seq 1 65535 | xargs -P … nc -z 全端口扫描跑到中途 Command aborted（失败信号：零输出）"
  - "只知道对端 ping 通，想知道 445/3389 这类常见服务端口开没开"
  - "准备现装扫描器再扫内网主机，想先确认这条路值不值"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0aa46-842a-765e-9e51-00867512a904
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

一句话主张：在 macOS（无第三方扫描器）上做内网端口探测，用「显式候选端口列表 + 后台并行 `nc -z -G 1`」一次工具调用就能跑完并出结果；而 `seq 1 65535 | xargs -P 300 … nc -z` 这类全端口暴扫会以 `Command aborted` 收场、零输出——端口列表必须先收敛，别指望全量扫描。

**为什么**：`nc` 每个端口都要等超时/RST 才返回，全端口 × 高并发会把整条调用拖进中止；而显式列表只有几十个端口，几百毫秒到数秒内就返回。本机也确实没有现成扫描器：`which nmap masscan` 无输出、`which smbclient nmap impacket-smbclient` → `(无第三方工具)`、`python3 -m pip list | rg impacket…` → `(无)`。

**证据**（会话 01a0aa46，目标 <lan-host>）：
- 一轮 13 端口（22/23/139/445/3389/5900/5985/5986/548/5901/8000/8080/9999）用 `for p in …; do (nc -z -G 1 … $p && echo "OPEN  $p") & done; wait` → 输出 `OPEN  445` + `--- scan done ---`。
- 二轮 29 端口（含 21/53/80/111/161/443/631/873/2049/3306/5432/8443/9000/9090/10000…）→ `--- 二轮扫描完成 ---`，无新 OPEN 行（结论：该机只开 445）。
- 全端口方案：`seq 1 65535 | xargs -P 300 -I{} sh -c 'nc -z -G 1 -w 1 <lan-host> {}'` → `Command aborted`，一条结果都没有。
- 现场装工具同样不划算：`python3 -m venv /tmp/smbenv && pip install impacket` 在 180s 的超时设置下同样 `Command aborted`，拿不到可用输出。

**边界**：本条只讲「怎么探测」，不解释探测结果的含义——445 开着不等于 SMB 可用（本会话 445 开、匿名会话仍被拒）。切片不足以判定全端口扫描被中止的确切原因（工具超时还是被中断），这里只把它当作「不可依赖」的观察。`nc -z -G 1` 的 `-G` 是 macOS/BSD nc 的连接超时参数，`-w 1` 与 `-G 1` 叠加时以切片所示组合为准，换平台要另测。
