---
id: retry-rewrite-log-dedup-by-key
type: lesson
status: candidate
scope: global
domain: metric-design
tags: [jsonl, dedup, retry, idempotency, metrics]
triggers:
  - "从 append-only 日志/JSONL 台账聚合指标（精度、覆盖率、调用次数）"
  - "任务失败重试会重写同一条逻辑记录（同一 session+id+channel 出现多行）"
  - "指标分母比实际事件数明显偏大、又找不到外部来源（失败信号）"
  - "对账脚本按行数统计，行数随重试次数增长"
  - "修正读法后历史百分比整体位移，需要判断是口径修复还是真实变化"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4d2-e53f-7341-b816-247fbf0b3018
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [coverage-denominator-is-a-moving-target]
---
**主张**：append-only 台账只要存在「失败重试重写同一逻辑事件」的写入路径，同一自然键就会留下多行；按**行数**聚合会把指标分母算大、比率失真（本例重复率约 19%）。读法必须按自然键去重（同一 `(session, id, channel)` 只保留**最后一次**写入），并把「原始行数 − 去重后条数」当例行体检指标：差值突然变大就是重试风暴或写路径重复的信号。

**为什么**：append-only 的语义是「只追加、不修改」，而「重试」在语义上是**重写同一逻辑事件**。两者叠加时，行数不再等于事件数——分母虚高会让所有比率类判据（精度、覆盖率、采纳率）系统性偏低，且与真实质量无关。去重键必须来自写入方约定的幂等键，而不是行内容或时间戳。

**证据**（session 01a0a4d2 的 slice「命令 ↔ 结果」）：
- 直接量：`raw 行 366（recall 364）→ 去重后 recall 295（重复 69 条）`，重复的键形如 `('019f921b-2cdc-74d3-a9fc-b503f02f008d', 'episode-agent-evo-…')` —— recall 通道 364 行里有 69 行是同一批自然键的重试重写（约 19%）。
- 修复提交（slice 显示 push `0937797..1302130`）：`fix: 对账去重读法 —— 重试重写的同一 (session,id,channel) 不再双计`。
- 回归：smoke 的 J 段断言从含重复的分母（期望 `33%（123/368）`）校正到去重后（实得 `34%（101/297）`），并新增「对账去重」守卫，最终 `PASS=137 FAIL=0`。

**边界/反例**：去重语义取决于写入语义——若同一自然键的不同行代表**多次真实事件**（例如同一 session 对同一条目多次 `get`），则不能去重，该计数本身就是指标。本例 `(session,id,channel)` 是幂等键（对账状态才是事实，重写只代表重试），所以保留最后一条：重试后的状态可能从 `relevant-unused` 改成 `adopted`，取第一条会读到过期结论。重复率约 19% 是本例快照，会随重试次数变化，不应直接套用。
