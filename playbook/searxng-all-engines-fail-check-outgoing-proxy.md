---
id: searxng-all-engines-fail-check-outgoing-proxy
type: bullet
status: validated
scope: global
domain: self-hosted
tags: [searxng, docker, proxy, troubleshooting]
triggers:
  - "searxng 所有引擎报 HTTP connection error"
  - "curl -x 代理超时 000 但裸 CONNECT 返回 200"
  - "searxng docker 容器正常但搜索全部失败"
  - "settings.yml 的 outgoing.proxies 指向宿主机代理"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:capture-2026-08-11-08-25-12-566-g9g1
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [local-proxy-env-blocks-api-client]
---
searxng docker 搜索全失败、容器却正常：本质是 `outgoing.proxies` 指向的宿主机代理上游死了，不是引擎或容器问题。

**特征**：所有引擎 HTTP connection error；`curl -x 代理` 超时 000，但裸 CONNECT 返回 200——代理隧道能建、无数据流，说明上游（如宿主机 7897 端口的代理）已死。
**应急修法**：settings.yml 注释掉 proxies，engines 显式启用 baidu/bing/sogou（国内直连可达），`docker restart` 即可；代理恢复后再取消注释。
**边界**：CONNECT 200 不代表代理可用，必须测实际数据流；别在引擎侧逐个排查。
**证据**：2026-08-11 本机 searxng 全引擎故障按上法定位并恢复。
