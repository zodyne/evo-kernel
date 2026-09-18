---
id: pi-jsonl-toolresult-toolcallid-pairing
type: lesson
status: candidate
scope: global
domain: pi
tags: [pi, jsonl, transcript, toolCallId, forensics, jq]
triggers:
  - "解析 pi 会话 jsonl 统计工具调用次数，或核对调用与结果是否成对"
  - "写 jq 过滤 pi transcript 时不确定记录类型、配对字段叫什么"
  - "会话被中断/闪退后，想找出哪些工具调用没有结果"
  - "把 jsonl 第 1 行当普通消息处理，报字段缺失或统计数偏大（失败信号）"
  - "统计出的工具调用数与'结果数'对不上，怀疑漏读或重复读（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ad-83f5-725c-a75a-f98c8ce559e8
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [evo-slice-normalize-toolname-case-and-path-field, pi-transcript-tool-args-encoding-is-per-tool]
---

主张：手工核对 pi 会话 jsonl 时，先按记录类型分流再数数——第 1 行是 `type: "session"` 的头（含 `version` / `id` / `timestamp`），其余是 `type: "message"` 的记录（带 `id` / `parentId` / `timestamp`）；其中工具结果类记录的字段是 `role` / `isError` / `toolName` / `toolCallId` / `content` / `timestamp`，**靠 `toolCallId` 回指工具调用的 id**。所以"每个调用是否都有结果、有没有孤儿结果"要用两个 id 集合的 diff 来判定，而不是数命令块个数。

**为什么**：这些记录是嵌套 JSON（`content` 是块数组），直接 `grep -c` 或忽略首行会把头记录/嵌套文本一起数进去，得出偏大的计数；而调用与结果分散在不同记录里，只有 id 集合 diff 才能给出"成对/孤儿"的确定结论。本会话正是这么做的（见证据）。

**证据（本会话命令 ↔ 结果）**：
- `… echo "=== line1 ==="; sed -n '1p' …` → `=== line1 === {"type":"session","version":3,"id":"01a09f18-05ae-7485-85f6-b4efb9c12374","timestamp":"2026-09-14T08:45:46…`（首行是会话头，不是消息）。
- `… echo "=== line7 keys ==="; …keys…` → `=== line7 keys === [0,1,2,3,4] ["content","isError","role","timestamp","toolCallId","toolName"]`（一条结果记录的键面；`content` 为数组）。
- `… echo "=== line27 raw ==="` → `{"type":"message","id":"70cc54ac","parentId":"73fc74cd","timestamp":"2026-09-14T08:46:28.595Z","messa…`（消息记录的形状）。
- `… echo "=== toolResult toolCallId/toolName ==="; … diff …` → `=== diff === call_00_62xPmfYSeHhPmWEk4PGo4452 call_00_daSezmqVrD9gVQDkgZZ74034 …`（按 id 集合 diff 做配对核对；切片在此 120 字截断，只看到参与比对的两个 id）。

**反例/边界**：诚实标注——本会话只用 pi 会话验证了上述字段名与首行结构，id 集合 diff 的完整结论在切片中被截断；未在其它 harness（Claude / Hermes）复验，那两套的字段命名与块结构不同（见 related 两条：工具名大小写/路径字段、以及 args 容器类型都是 per-harness、per-tool 的）。结论表述依赖 `toolCallId` 字段名与"回指调用 id"的语义，未做反例（如结果记录缺 `toolCallId`）的普查。
