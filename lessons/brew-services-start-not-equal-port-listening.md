---
id: brew-services-start-not-equal-port-listening
type: lesson
status: candidate
scope: global
domain: macos
tags: [homebrew, brew-services, launchd, lsof, 探活]
triggers:
  - "brew services start 输出 Successfully started 后立刻探活端口"
  - "`brew services start X && lsof -iTCP:<port> -sTCP:LISTEN` 整链 exit 1，但 start 明明打了 Successfully started（失败信号）"
  - "launchd 托管的服务刚启动就 curl/lsof 探测，得到无监听/连接拒绝的假死结论"
  - "把服务启动和端口探活串在一条 && 链里，拿整链退出码判成败"
created: 2026-08-05
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fd1ca-7709-7957-a1e2-e90fb2088e95
last_verified: 2026-08-05
superseded_by: null
schema_version: 1
related: [diff-in-and-chain-exit-1-masks-success, stdio-mcp-server-shell-background-probe-false-dead, privoxy-share-mac-vpn-to-lan]
---

`brew services start` 打印 `Successfully started` 只表示 **launchd job 已加载**，不代表 daemon 已完成 bind 端口。紧随其后（即使 sleep 2）用 `lsof -iTCP:<port> -sTCP:LISTEN` 探活可能什么都匹配不到——lsof 无匹配行时 exit 1，整条 `&&` 链就被渲染成失败，形成「启动成功却像启动失败」的假死信号。

会话证据：`brew services start privoxy && sleep 2 && lsof -iTCP:8118 -sTCP:LISTEN -P -n` 输出 `==> Successfully started privoxy` 但整链 exit 1；再过约 2 秒单独跑 `lsof -iTCP:8118 -P -n`，privoxy（PID 10624）已在 8118 监听——服务一直是好的，只是首次探活太早。

做法：start 与探活拆成两条命令分别判读；探活留足启动余量或做几次重试；不要用 `start && 探活` 的整链退出码当成败判据（与 diff 退出码掩盖成功同属"命令链末条命令的退出码语义"陷阱）。
