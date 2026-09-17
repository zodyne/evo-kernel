---
id: retired-service-leaves-dangling-monitor-probe
type: lesson
status: validated
scope: global
domain: system-governance
tags: [decommission, monitoring, health-check, mcp]
triggers:
  - "退役/下线一个自建服务或本地 MCP server（gbrain 这类）后，巡检仍报 degraded"
  - "curl 探测某个已下线端点的健康检查，返回 Failed to connect / connection refused"
  - "清理退役服务的收尾：监控探针、健康检查链、告警源是否同步下线"
  - "晨报/巡检持续报连接拒绝，但服务本身早就退役了（失败信号）"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:cron_56cb07fbe7c8_20260914_093009
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: [macos-tailscale-half-uninstall-wrapper-extension-remains]
---

# 主张

退役一个自建服务（尤其本地 MCP server）后，指向它端点的巡检/健康检查探针不会自动失效——探针会持续返回连接拒绝（`curl: (7) Failed to connect ... Couldn't connect to server`），把健康门禁误报成 degraded。退役时必须同步退役/更新检查链。

# 为什么

探针（curl / 健康检查脚本）是独立配置的，与服务进程的启停不联动。服务下线后，探针仍在定时打一个已经死掉的端点，得到的是连接拒绝，而非「服务已退役」这一语义——巡检无从区分「真故障」和「已下线」，只能报 degraded。

# 反例 / 边界

- 只适用于「探针主动探测已下线端口」这种 pull 型检查。服务主动上报（push 型监控 / 心跳上报）不会出现这类假阳性，因为上报源随服务一起消失。
- 若退役时已同步改掉检查链，则不会触发本条——教训点在「退役清单要覆盖监控/检查项」，而不只是进程和数据。
- 与卸载残留（如 Tailscale 卸载后 wrapper 报找不到二进制）同属「退役收尾清理」族，但本条的失败形态是连接拒绝而非残留文件报错。

# 证据

2026-09-14 晨报 cron（session:cron_56cb07fbe7c8_20260914_093009）里，`curl -sS -m 8 -X POST http://localhost:18795/mcp -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' -d '{...}'` 返回：

```
curl: (7) Failed to connect to localhost port 18795 after 0 ms: Couldn't connect to server
```

末条结论判定「健康：degraded」，并把「GBrain 检查链失效 + 告警簇积压」的根因标为「gbrain 退役收尾两批清理待批」。即：gbrain 已退役（MCP 端点 18795 下线），但巡检里的 GBrain 检查链仍指向它，导致连接拒绝 + degraded 误报。
