---
id: gateway-unknown-model-503-model-not-found
type: fact
status: candidate
scope: global
domain: llm-tooling
tags: [nanoradar, gateway, model_not_found, http-503, error-signature]
triggers:
  - "调 nanoradar / NovaSky 网关返回 HTTP 503，想判断是模型问题还是上游/网络问题"
  - "网关响应体里出现 model_not_found 或 No available channel for model（失败信号：只看状态码就当成服务不可用）"
  - "把一个没在网关注册/没配 channel 的模型名（如不存在的 claude-opus-5）打给网关做探测"
  - "排查模型调用失败，要区分『网关没这个模型』与『凭据错』『连不上』"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b749-e05a-7664-9da0-1444e519d55d
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [claude-code-nanoradar-gateway-settings, novasky-deepseek-max-tokens-param-ceiling]
---

# 未在网关注册的模型名，换来的是 HTTP 503 `model_not_found`（No available channel），排查方向是模型名而不是鉴权/网络

**主张**：对 nanoradar / NovaSky 网关请求一个没有对应 channel 的模型名，网关返回的是 **HTTP 503**，响应体 `{"error":{"code":"model_not_found","message":"No available channel for model <名称>"}}`——语义是「网关没给这个模型配 channel」，即模型名/别名没映射，而不是凭据错（401/403）或模型不存在于 API（404）。看到 503 + `model_not_found` 应先核对你请求的模型名是否在网关注册，别去查 token、网络或网关存活。

**为什么**：503 通常被读成「服务端故障/上游不可用」，很容易把人引向重试、查网关进程、查网络；而这里的 503 只是 new-api 网关对「无可用 channel」这一业务状态的封装，`code: model_not_found` 才是判据。同类「模型没映射」现象在 related 条目里记录为 404（haiku 别名未映射）——两种码并存，不能按一种形状去猜。

**证据**（本会话切片，命令 ↔ 结果）：会话用 Python 读 `~/.pi/agent/models.json` 的 provider 配置并直连网关发请求，其中模型名填一个未知名：

- 结果行（切片按 120 字符截断）：`-- 未知名 claude-opus-5    HTTP 503 -> {"error":{"code":"model_not_found","message":"No available channel for model claude-…`
- 同批请求走的是网关的 Anthropic 分流端点（切片另见 `POST https://nanoradar.tail7a20…`、`gateway leg : https://nanoradar.tail7a2064.ts.net/v1/messages`），即 503 是网关对 `/v1/messages` 的正常业务应答，不是连接失败。

**边界 / 反例**：

- 本条只验证了「模型名不存在/未映射」这一种成因；不能反推「所有 503 都是模型名问题」——判据要连 body 的 `code: model_not_found` 一起看，只看状态码不够。
- 响应的 message 在切片里被截断（`…for model claude-`），不要凭本条猜完整文案；以实际响应体为准。
- 探测未知模型时，网关仍会正常建连并返回结构化错误，所以「有 JSON 错误体」不等于「请求格式对」——它恰恰证明了端点可达、鉴权没问题，剩下的变量就是模型名。

## 2026-09-22 独立复核增补

下列是复核时在本机跑过的**自包含最小复现**：

```
KEY=$(awk -F= '/^NOVASKY_API_KEY=/{print $2; exit}' ~/.hermes/.env)
curl -sS -w '\nHTTP %{http_code}\n' -X POST https://nanoradar.tail7a2064.ts.net/v1/messages \
  -H "x-api-key: $KEY" -H "anthropic-version: 2023-06-01" -H "content-type: application/json" \
  -d '{"model":"claude-opus-5","max_tokens":16,"messages":[{"role":"user","content":"hi"}]}'
# 实测 2026-09-22 -> HTTP 503
# {"error":{"code":"model_not_found","message":"No available channel for model claude-opus-5 under group default (distributor) (request id: ...)","type":"new_api_error"}}
# 对照 1（凭据错）：同 URL 把 x-api-key 换成 BADKEY -> HTTP 401 {"error":{"code":"","message":"Invalid token ..."}}
# 对照 2（端点无关）：改打 https://nanoradar.tail7a2064.ts.net/v1/chat/completions（Bearer）-> 同样 HTTP 503 model_not_found
```


**审核给出的修改意见（要点）**：删去证据节第 2 条「同批请求走的是网关的 Anthropic 分流端点」这层论证——它既无切片支撑（产生 503 的命令被截断），也不是判据：2026-09-22 复核发现同一未知名在 /v1/chat/completions 上也返回同样的 503 model_not_found（端点无关）。把 message 换成已复现的完整文案并补上 `"type":"new_api_error"`（可见其确为 new-api 业务应答而非连接失败），并注明产生 503 的命令在切片里被截断、不能照抄重跑。主张本身、边界/反例节均维持原样。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 同批请求走的是网关的 Anthropic 分流端点

**判定**：keep-with-fix · 拟 keep-lessons · 原证据快照风险=high · 复核时本机可复跑=true
