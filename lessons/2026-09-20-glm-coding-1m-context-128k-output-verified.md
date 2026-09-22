---
id: glm-coding-1m-context-128k-output-verified
type: fact
status: candidate
scope: global
domain: llm-tooling
tags: [glm, bigmodel, z-ai, models-json, max-tokens, context-window, probe]
triggers:
  - "给 pi 的 glm-coding provider（GLM-5.2 / 5.3 / 5.3-flash）配 contextWindow 与 maxTokens"
  - "厂商文档写『上下文窗口 1M / 最大输出 Tokens 128K』，犹豫要不要直接写 maxTokens=131072（失败信号：只抄文档没实测）"
  - "GLM 请求报 max_tokens 相关错误或回复被截断，怀疑上限设错"
  - "改完 ~/.pi/agent/models.json 后核对字段值是否按 1024 进制落盘"
  - "给 GLM 写 128000 而不是 131072，输出预算比文档少一截（失败信号）"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b965-0941-75eb-8af3-647a9ae53e12
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [pi-contextwindow-960k-gateway-probe, novasky-deepseek-max-tokens-param-ceiling, pi-provider-config-split-models-json-vs-models-store]
---

# GLM 的 1M/128K 落到 pi models.json 是 `contextWindow: 1000000` + `maxTokens: 131072`，且 131072 实测被服务端放行

**主张**：GLM（bigmodel.cn / z.ai）文档的「上下文窗口 1M、最大输出 Tokens 128K」，对应 pi `~/.pi/agent/models.json` 里的 `contextWindow: 1000000`、`maxTokens: 131072` —— 128K = 128×1024 = 131072，不是 128000。`max_tokens=131072` 已用真实请求实测被接受（返回 http=200 且带正常响应体），不是只能写小一档的保守值。

**为什么**：文档的 "K" 与 API 的 token 计数都是 1024 进制，配置里写 128000 会平白少一截输出预算；而只信文档不实测，又可能撞上服务端参数校验（同类条目记录过 deepseek 网关 max_tokens 设太大报 HTTP 400 的情况），因此「按文档取值 + 一次 curl 实测放行」是确认口径的最低成本做法。

**证据**（本会话切片，命令 ↔ 结果）：

- 文档抓取：`===== glm-5.2 =====  … 上下文窗口 1M 最大输出 Tokens 128K …`（切片内输出被截断）。
- 实测放行：命令 `实测 glm-5.3-flash 是否接受 max_tokens=131072` → `http=200 total=3.092274s {"id":"msg_20260919200554b3f2838134164bc1","typ…`。
- 落盘核对：`=== JSON 有效性 + 字段核对 ===  glm-5.2 contextWindow=1,000,000  maxTokens=131,072  glm-5.3 contextWindow=1,0…`。
- 本会话的写操作只有 `~/.pi/agent/models.json` 一处（切片「写/改文件」段），且改前有备份 `models.json.bak-20260919-200614-pre-glm-1m-ctx`。

**边界 / 反例**：

- `max_tokens=131072` 的实测对象只有 **glm-5.3-flash**；glm-5.2 / glm-5.3 的 131072 是文档口径，本会话未逐个打请求验证。
- 1M contextWindow 来自文档页面文案（切片里 glm-5.2 页明确写 1M；glm-5.3 的核对行被截断），若走网关/中转，实际上限可能低于厂商直连（见 related 的 contextWindow 探针条目）。
- 条目不涵盖 z.ai 与 bigmodel.cn 两个端点的行为差异；换端点前重新实测一次。

## 2026-09-22 独立复核增补

**复核给不出最小复现**（见下）。


**审核给出的修改意见（要点）**：改『为什么』段：删去/更正那句『文档的 \"K\" 与 API 的 token 计数都是 1024 进制』——本条目自己的落盘值就反证它：上下文窗口 1M → 1000000 是十进制(10^6)，不是 1024 进制(1M×1024 会是 1048576)；只有输出 token 上限 128K=2^17=131072 才按 2 的幂换算。机制应表述为『输出 token 上限按 2 的幂(1024)换算、上下文窗口按十进制(1000)』，或直接删去机制、只留实测口径。把『deepseek 网关 400』那句标明是引自 related 条目、非本会话证据。并修正证据节第 2 条：它把 echo 文案当作『命令』引用，应注明真实命令在切片中被截断、不可照抄重跑。主张本身（配置值 1000000/131072 且 131072 服务端放行）站得住，无需改写。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 『文档的 "K" 与 API 的 token 计数都是 1024 进制』——切片无此依据，且被条目自身反证：同一主张里上下文 1M 落成 1000000（=10^6，十进制），只有输出侧 128K=2^17=131072 是二进制。该机制解释是错的，不能当口径来源。
- 『同类条目记录过 deepseek 网关 max_tokens 设太大报 HTTP 400 的情况』——引自 related 条目 novasky-deepseek-max-tokens-param-ceiling，本切片内无任何对应输出；作为『为什么』的论据被搬进来当机制，属超出本会话证据。

**判定**：keep-with-fix · 拟 keep-lessons · 原证据快照风险=high · 复核时本机可复跑=false
