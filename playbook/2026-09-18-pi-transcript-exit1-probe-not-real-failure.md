---
id: pi-transcript-exit1-probe-not-real-failure
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, transcript, exit-code, metrics, failure-rate]
triggers:
  - "用 pi 会话 transcript 的 isError / 退出码统计工具失败率或审计命令质量"
  - "统计出的失败数很大，但绝大多数退出码是 1（失败信号：把探路命令当失败）"
  - "ls / cat / test 目标不存在这类探测命令被计入 failed"
  - "要报『这个 harness 里有多少命令失败』这种口径的数"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09e85-e0fb-75a9-9255-6adde3fc97aa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [bash-loop-child-steals-stdin, pi-agent-summary-per-class-counts]
---

**主张**：拿 pi transcript 的 `isError` 计数当命令失败率会严重失真：实测 287 条 bash isError 里 241 条是 exit 1（84%），其中大量是 `ls`/`cat` 目标不存在这类探路命令——探测用非零退出表达"没有这个东西"，是正常用法。统计失败构成必须先按退出码 + 命令形态分流（探路失败 / 程序真报错 / 被中止 / 命令不存在），再报数。

**为什么**：agent 会话里探路命令占比很高，直接把 isError 计数当"harness 错误率"会系统性高估，进而把优化力气花错地方。

**证据**（本会话命令 ↔ 结果，脚本扫 `~/.pi/agent/sessions` 下 230 个会话的 jsonl）：
- `bash isError 总数: 287`，退出码分布 `{1: 241, None: 13, 28: 13, 2: 8, 127: 6, 128: 3, 7: 2, 6: 1}`。
- 同一分析的分流标注：`## ls/cat 目标不存在 → exit 1（探测，假失败）`；全量 360 条 isError 的构成里，`bash: 程序真报错 102 28%`、`bash: 其它非零退码 121 34%`。

**边界/反例**：exit 1 也可能是真失败（真实命令错误、断言失败），不能只看码位；判据是"分流后再统计"，不是"exit 1 一律不算失败"。缺乏输出/命令形态佐证时不要下结论。
