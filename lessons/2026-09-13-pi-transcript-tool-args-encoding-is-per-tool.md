---
id: pi-transcript-tool-args-encoding-is-per-tool
type: lesson
status: candidate
scope: global
domain: pi
tags: [pi, jsonl, transcript, parsing, tool-call]
triggers:
  - "解析 pi/Claude 会话 jsonl 做工具调用统计/对账"
  - "从 pi transcript 提取工具调用参数"
  - "给 evo slice 等解析器接 pi 会话源"
  - "假设 toolCall 的 arguments 一定是对象、或一定是 JSON 字符串"
  - "取 Agent/子代理调用的参数时得到字符串而不是对象（失败信号）"
created: 2026-09-13
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a099a8-07d2-766c-b240-9eaed5f6ca6d
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [evo-slice-normalize-toolname-case-and-path-field]
---

# 工具调用参数编码是 per-tool 的，不能按 harness 一刀切

## 主张

解析 pi/Claude 会话 transcript 的工具调用参数时，**不要假设「args 一定是对象」或「一定是字符串」**——编码单位是「哪个工具」，不是「哪个 harness」：

1. 顶层 `toolCall`（pi）/ `tool_use`（Claude）块的 `arguments` / `input` 是 **dict**；
2. **`Agent`（子代理）工具的载荷**里嵌着一层 `{name, args}`，其中 `args` 是**字符串**（子代理的 prompt，通常是 JSON 文本）。

归一化要按块的内容形态判断（dict 直接用；字符串先 `json.loads`、失败或纯文本则包成 `{"text": 原文}`、null → `{}`），而不是给整个 harness 定一条「args 是对象/是字符串」的规矩。

## 为什么

按「某 harness 的 args 是字符串」写解析器，在 99.9% 的调用上是对的、在 Agent 调用上就落空（反之亦然）；反过来若按「一定是对象」写，Agent 那一层取字段就炸。两种假设都只在**多数样本**上成立，于是很容易通过手头几个样本的抽查。

## 证据（2026-09-18 独立复验，命令 ↔ 结果）

- 遍历 `~/.pi/agent/sessions/**/*.jsonl` 中含 `toolCall` 的 801 行，统计块键形态与 `arguments` 类型：
  `('arguments','name','type') × 572`；按工具分：`dict/bash ×4783`、`dict/read ×688`、`dict/edit ×471`、`dict/web_search ×287`、`dict/write ×123`、`dict/grep ×89`、`dict/Agent ×44`、`dict/StructuredOutput ×43`、`dict/ask_user ×42`、`dict/ls ×20`、`dict/get_subagent_result ×17`、`dict/SubagentWorkflow ×10` ——
  **`arguments` 为 dict 者 6647/6647，无一是字符串**。
- 全样本中「嵌套 `{name,args}` 且 `args` 为字符串」只出现 **1 次**，其 `name='claim-audit'`、`args` 前 90 字为 `'{"text": "## 答案：13 个自动，4 个必须手动\n\n我查了安装后实际的 frontmatter…'` —— 即 Agent 工具的载荷，不是 pi 的 transcript 编码。
- 另一路证据：`bin/evo` 的 `slice` 解析器注释与实现（`recordCall`，约 959–990 行）按 harness 分别处理——pi/Claude 取 `o.input`（dict），Hermes/OpenAI 取 `o.function.arguments`（**JSON 字符串**）——也不支持「pi 的 args 是字符串」。

## 边界 / 反例

- 与 `evo-slice-normalize-toolname-case-and-path-field` 互补：那条讲**同一 harness 内工具名大小写与路径字段名** per-harness（`Bash`/`file_path` vs `bash`/`path`）；本条讲**参数容器本身的类型**（dict vs 字符串）连 harness 内部都不统一。
- Hermes/OpenAI 形态（`function.arguments` 为字符串）是另一套 harness 的约定，不要拿来推断 pi。
- 反例方向同样要防：见到一次字符串就断言「该 harness 的 args 是字符串」——本条的由来正是这个误判。
