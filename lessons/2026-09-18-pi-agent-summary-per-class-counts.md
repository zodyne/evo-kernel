---
id: pi-agent-summary-per-class-counts
type: lesson
status: candidate
scope: global
domain: pi
tags: [pi, jsonl, agent-summary, tool-call-count, jq, transcript]
triggers:
  - "要报/引用某次 pi 会话的工具调用次数（『跑了 N 次工具调用』）"
  - "在 pi 会话 jsonl 里看到 customType:\"agent-summary\" 事件，想直接把 commands 字段当工具调用总数"
  - "复核报告里的工具调用次数偏小（失败信号：数字小于按 message 事件逐条 jq 统计的总数）"
  - "需要用 bash / grep / read 分类口径解释一次会话到底跑了多少步"
  - "解析 pi transcript 做用量或审计统计，不确定 summary 字段与逐条统计哪个是全量"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ae-d215-725c-a75a-f98fbd044160
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pi-jsonl-toolresult-toolcallid-pairing, pi-transcript-tool-args-encoding-is-per-tool]
---
pi 会话 jsonl 里的 `agent-summary` custom 事件（`{"type":"custom","customType":"agent-summary","data":{…}}`）是**按工具类拆分的计数，不是工具调用总数**：`commands` 只等于 bash 命令数，`reads`/`edits`/`writes` 各数一类，其余工具（本次是 grep 等）落在被截断的其它类字段里。要「这次会话跑了多少次工具调用」，必须把各类相加，或直接 jq 逐条数 `type:"message"` 记录里的 toolCall；单取 `commands`（甚至 `commands+reads`）都会系统性少算。

**为什么**：字段名（commands/reads/edits/writes）本身就宣告了各自只覆盖一类工具，但这个事件叫 “summary” 很容易被当成全量概览直接引用。一旦引用，产出的是静默偏小的数字——本次复核里同一会话 `commands=106`，而按逐条记录数出的工具调用总数是 141（106 bash + 21 grep + 13 read + 1），差额 35 次全部在其它类字段里。

**证据（本会话命令 ↔ 结果）**：
- 从 S 的 jsonl 逐条抽出 bash 命令：`… jq -r 'select(.type=="message" …' …` → `106 /tmp/S_cmds.txt`（bash 命令数 = 106）。
- 同一会话的 summary 事件：`echo "=== agent-summary event …"` → `{"type":"custom","customType":"agent-summary","data":{"commands":106,"reads":13,"edits":0,"w…`——`commands` 恰等于上面逐条抽出的 bash 数，`reads=13`，后面还有被截断的其它类字段。
- 复核结论（末条 assistant）：S 实际工具调用数为 141（`106 bash + 21 grep + 13 read + 1`）；报告里写的「113 次工具调用」被判为硬错误（quote_errors）。
- 推断链：`commands`(106) ≠ 141、`commands+reads`(119) ≠ 141，而 grep 等工具确实存在于该会话 → summary 的分类计数不是总数。

**边界 / 反例**：
- 诚实标注：本次只对 S 一个会话做了逐条统计（命令+结果佐证），未跨会话普查各字段关系；被截断处没看到的字段语义（如 `failed` 是跨类子集还是独立类）未验证。
- 只适用于带 `agent-summary` custom 事件的 pi transcript；Claude / Hermes transcript 无此事件。
- 逐条统计本身也有口径坑（记录类型分流、toolCallId 配对），见 related 两条；本条只管「不要拿 summary 的单字段当总数」。

**失败信号（未来命中即该想起本条）**：
- 报告里的工具调用次数小于 `jq` 逐条数出来的总数，或与「bash + grep + read + …」的分项和加不上。
- 有人拿 `agent-summary.commands` 直接当「N 次工具调用」引用。
