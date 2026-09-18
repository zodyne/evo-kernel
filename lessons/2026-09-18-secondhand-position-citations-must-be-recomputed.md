---
id: secondhand-position-citations-must-be-recomputed
type: lesson
status: candidate
scope: global
domain: research-methodology
tags: [citation, line-number, count, audit, verification, transcript]
triggers:
  - "写或复核含『共 N 条』『<文件>:<行号>』这类具体引用的分析报告/蒸馏产物"
  - "报告里的数字或行号是肉眼从大段命令输出里数出来的，没有对应的取数命令"
  - "把会话转录/日志里的条目数写进结论或提案"
  - "抽样复核他人报告的位置类引用，要决定优先查哪一类"
  - "复核发现计数差 1、行号偏几行、指到的行不是声称的内容（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ad-83f5-725c-a75a-f98c8ce559e8
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [adversarial-review-repro-as-written, doc-selfreported-counts-drift, markdown-doc-anchor-count-drift]
---

主张：分析报告里带具体位置的引用（「共 N 条」「<文件>:<行号>」）必须由命令当场产出并原样落盘——计数用 `jq` 按类型分组统计、行号用 `rg -n` / `sed -n` 直接取——**不能人眼从大段输出里数**；复核既有报告时，这类引用是最高产的抽查面。

**为什么**：本会话复核一份多会话调查结论，抽 13 条带具体位置的引用即发现 4 条错误（末条结论 `verified = false`）。其中两条当场被命令证伪：

| 报告声称 | 命令与结果（本切片） | 实况 |
|---|---|---|
| custom 事件「8 条」 | `echo "=== custom count main ==="; …jq…` → `=== custom count main ===    7` | 7 条 |
| bash-guard 在 session2 第 44 行 | `=== 217Z line numbers of bash-guard === 39:{"type":"message","id":"ab6698a1",…}` | 第 39 行（44 行是另一条 `isError` 记录） |

位置类引用读起来像稳定事实（不像"HEAD 指针"那样显然会变），所以不会主动去核；但它是二次转写的手工件，误差直接污染结论。把数字交给命令产出，误差面就只剩命令本身。

**做法**：① 写报告时，凡数字必附生成它的命令（如 `jq -r '…' | group_by(.type) | …`、`rg -n '<锚点>'`），粘贴其原始输出而不是转述；② 复核时按"带位置的引用"分层抽样，逐条回源重跑，先查计数与行号这两类；③ 行号要连内容一起核（本例 44 行确有记录、但内容不是被引用的那条）。

**反例/边界**：这条不覆盖"发现方给了 repro 命令"的情形——那类应先逐字复现其命令（见 related `adversarial-review-repro-as-written`）；也不替代时间漂移类核对（文档自述数字随代码演进过期，见 `doc-selfreported-counts-drift`、`markdown-doc-anchor-count-drift`）。本条的机制是**人手转写/计数误差**，与"对象后来变了"无关。诚实标注：末条结论称 4 条错误，切片只完整展开其中 2 条，另 2 条在 200 字截断处。

**证据**：见上表两行命令↔结果（切片 `## 命令 ↔ 结果` 第 12、22 条）与末条 assistant 的复核表（`quote_error`：8→7、session2:44→39）。
