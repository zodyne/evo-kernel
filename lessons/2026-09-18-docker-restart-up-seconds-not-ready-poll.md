---
id: docker-restart-up-seconds-not-ready-poll
type: lesson
status: candidate
scope: global
domain: self-hosted
tags: [docker, restart, readiness, curl, shell]
triggers:
  - "docker restart 后用固定 sleep 就去读应用接口/配置（失败信号：JSON 解析异常或空响应）"
  - "容器 Status 显示 Up N seconds，但服务接口还没起来"
  - "写『重启后自动复测/取证』的脚本"
  - "抓 /config?format=json 报 JSONDecodeError，怀疑配置被改坏了"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d3-c853-744a-939b-f6e91f2f995b
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# `docker restart` 后 `Up N seconds` 不等于应用就绪，要轮询接口 200 再读配置

**主张**：`docker restart` 之后 `docker ps` 报 `Up 6 seconds` 只说明容器进程在，不代表应用已能服务：此时紧接着 `curl /config?format=json` 拿到的是非 JSON 响应（python 侧直接 `JSONDecodeError` traceback）。脚本里正确做法是**轮询目标接口直到 HTTP 200** 再读配置（本会话用的就是 `for i in $(seq 1 20); do curl -s -m 5 -o /dev/null -w '%{http_code}' http://localhost:8888/; if [ "$code" = "200" ]; then …` 的循环，打印 `ready after 1 tries` 后才继续）。

**为什么**：把"容器 running"当成"应用 ready"会让重启后的自动化步骤随机失败，而且失败信号长得像"配置写错了"（解析异常），把人往错误方向带——本会话正是在改完 settings.yml 重启后撞上这个，先怀疑配置格式，实际只是接口没起来。

**证据（本会话命令 ↔ 结果）**：
- `docker restart searxng >/dev/null && sleep 6; echo "=== 容器状态 ==="; docker ps --filter name=searxng --format '{{.Status}}'; …`
  → `✗ === 容器状态 === Up 6 seconds === 启用状态 === Traceback (most recent call last):   File "<string>", line 3, in <module>     d=j`（容器 Up，但 `/config` 返回的不是 JSON）
- 改成轮询：`for i in $(seq 1 20); do code=$(curl -s -m 5 -o /dev/null -w '%{http_code}' http://localhost:8888/ 2>/dev/null); if [ "$code" = "200" ]; then echo "re…`
  → `ready after 1 tries`，之后 `curl /config?format=json` 正常返回（`google cse enabled = [False]`）

**反例/边界**：
- 轮询打印的是 `ready after 1 tries`，说明服务那时已就绪；切片无法判定 `sleep 6` 的失败是"差一点点"还是"某次启动特别慢"。成立的是"别把 `Up N seconds` 当就绪判据"，**不**成立"必须等很久"。
- 就绪判据要用真正依赖的那个接口（这里是 `/`，读配置是 `/config`）；对更慢的后端，探 `/` 通了不代表 `/config` 已可用。

**失败信号（未来命中即该想起本条）**：重启脚本里是 `restart && sleep N` 然后直接解析响应；或看到解析异常先怀疑"配置被改坏了"而没先确认服务是否 ready。
