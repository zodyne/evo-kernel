---
id: claude-relay-outage-layered-diagnosis
type: bullet
status: deprecated
scope: global
domain: llm-api
tags:
- claude-code
- 中转站
- relay
- 诊断
- model-not-found
triggers:
- Claude Code 中转站所有模型突然不可用
- API 返回 Upstream access forbidden
- model_not_found 分不清是网络、鉴权还是上游问题
- 排查第三方 API 端点故障要分层定位
created: 2026-08-03
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: capture:capture-2026-08-03-11-11-10-371-uf00
last_verified: 2026-08-12
superseded_by: skill:network-reachability-diagnosis
schema_version: 1
related: []
---
排查 Claude Code 中转站不可用的分层诊断法，逐层缩小故障域：

1. **curl 测连通性**——网络层是否通；
2. **带 token POST `/v1/messages` 请求一个肯定不存在的模型名**——若返回 `model_not_found`，说明网络 + 鉴权都正常；
3. **再请求该站 `/v1/models` 列表里的模型**——若全部返回 `Upstream access forbidden`，则是中转站上游账号被封/欠费，服务端问题，本地无解；
4. **注意 `settings.json` 的 model 别名**（如 opus）解析出的具体型号必须在该站模型列表内，否则上游恢复后仍会 `model_not_found`。

**案例**：api.gpteamservices.com 2026-08-03 全模型 upstream forbidden，但 GLM 线路正常——按层定位后直接切线路，没在本地配置上浪费排查。

**边界**：第 3 层结论"服务端问题"只对中转站/代理成立；直连官方 API 时 upstream forbidden 另有含义。
