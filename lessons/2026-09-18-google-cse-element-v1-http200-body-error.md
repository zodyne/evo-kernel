---
id: google-cse-element-v1-http200-body-error
type: lesson
status: candidate
scope: global
domain: api-design
tags: [google-cse, http-status, error-handling, risk-control, api]
triggers:
  - "判定 Google CSE（cse.google.com / element/v1）是否被限流或风控"
  - "调用第三方接口只拿到 HTTP 200 就认为成功（失败信号）"
  - "响应体形如 /*O_o*/ _({...}) 不是纯 JSON，json 解析报错"
  - "排查某引擎/接口『明明状态码 200 却没有结果』"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7d3-c853-744a-939b-f6e91f2f995b
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# Google CSE element/v1 被限流时返回 HTTP 200，真正的错误码 429 在 body 里

**主张**：Google CSE 的 `element/v1/s` 接口触发风控/限流时**不**用非 2xx 表达失败——HTTP 状态码仍是 `200`，真正的结论在响应体里的 `{"error":{"code":429,"message":…}}`；而且响应体前面还有 `/*O_o*/ _(…)` 这类前缀，不是纯 JSON。所以判断"这个引擎是不是被限流了"必须解析 body 的 `error.code`，只看 `%{http_code}` 会把它判成成功。

**为什么**：这是 Google 系接口常见的"状态码表示传输成功、错误码表示业务失败"两层协议。排查搜索链路时若以状态码为验收口径，就会得出"接口通、没问题"的相反结论，把风控问题漏到上一层（表现为查询 0 条而不是报错）。

**证据（本会话命令 ↔ 结果）**：
- 容器外经代理手工复现（拿到 CSE token 后按 google_cse 引擎同参打 element/v1）：
  `token 获取: OK | cse.js status: 200 | bytes: 9097 element/v1 status: 200 body head: /*O_o*/ _({"error":{"code":429,"messag…`
- 同一复现被写进排查归档并在提交时通过凭据扫描，正文口径为：
  `> 复现命令（拿到 cse_token 后打 element/v1）：响应是 **HTTP 200**，429 在 body 里`

**相关**：与同批提案 `http-200-may-be-bot-check-page`（200 可能是人机校验页，须验正文身份）同属"200 不等于成功"这一类，但失效面不同——那条是 HTML 空壳，本条是 JSON 错误码藏在 body 里。

**反例/边界**：
- 切片里只看到响应体的形状（`/*O_o*/ _({…}`）与 429 结论，**没有**看到"剥掉前缀再 json.loads 成功"的代码/输出，别把"解析方式"当已证事实引用。
- 200+429 是 Google CSE 这一接口的实测形态，不能外推成"所有 Google 接口限流都返回 200"。

**失败信号（未来命中即该想起本条）**：写完探针看到 `http=200` 就下结论"通道正常/未被限流"，而实际拿不到结果。
