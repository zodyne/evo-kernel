---
id: transcript-absence-claim-must-search-thinking-blocks
type: lesson
status: validated
scope: global
domain: review
tags: [transcript, grep, false-negative, thinking-block, verification, pi]
triggers:
  - "复核『某关键词在会话记录里从未出现 / rg 命中 0』这类否定断言"
  - "按 transcript 全文或正文块搜索后就准备下『不存在/没提过』结论"
  - "报告把 thinking / 推理块排除在检索范围外（失败信号：假阴性被当成事实）"
  - "要判某个术语是会话结论，还是只是 thinking 里被权衡过的候选假设"
  - "抽取 pi / Claude 会话 jsonl 做关键词存在性检查，不确定该搜哪些块类型"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7af-fee9-725c-a75a-f993fad354fe
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [subagent-transcript-exec-vs-mention, checker-positive-control-or-negative-void, located-quote-claims-must-be-grepped-in-source]
---

# 判定「某关键词在会话记录里从未出现」前，必须把 thinking 块纳入检索范围

**主张**：对会话 transcript 下「某词从未出现 / `rg` 命中 0」这类否定断言前，必须按块类型分别检索——assistant 正文、**thinking（reasoning）**、工具调用、工具结果——并把「搜了哪些块、各命中多少」写出来。只搜正文与工具块就宣布"从未出现"，会静默漏掉 reasoning 流，得到无法被自己发现的假阴性。

**为什么**：pi / Claude 的会话 jsonl 把 thinking 与正文分开存放；思维链里会大量出现被权衡、被否决的候选假设与术语，而正文里一个字都不提。于是"正文 grep 0"与"从未出现"之间隔着一整条 reasoning 流。这类否定断言常被用来裁决某个假设是否被讨论过、给报告定级或推翻结论，假阴性会直接把复核引向错误方向。

**证据（本会话命令 ↔ 结果，切片逐字）**：
- 复核者先把被审会话按块类型拆成 4 个流再检索：`371 /tmp/rev_text.txt  4673 /tmp/rev_think.txt  125 /tmp/rev_tools.txt  0 /tmp/rev_res.txt`（结果流初次为空，后续重抽为 8539 行）。
- `for p in ExitFree exit_on_quit exit_on_close; do … rg -c "$p" /tmp/rev_think.txt /tmp/rev_text.txt /tmp/rev_res.txt /tmp/rev_tools.txt …` → `== ExitFree == /tmp/rev_think.txt:3`、`== exit_on_close == /tmp/rev_think.txt:1`，`exit_on_quit` 四个流全无命中——**命中全部落在 thinking 流**，正文/工具/结果流均为 0。
- `rg -n "exit_on_close|ExitFree" /tmp/rev_think.txt` → `61:Actually, wait. A very likely candidate for "闪退" … **ExitFree**/flatten.nvim …`——原会话确实在 thinking 里权衡过该候选解释。
- 末条 assistant 复核结论：报告称该会话「从未出现 `ExitFree` / `exit_on_quit` / `exit_on_close` / `TermClose`（rg 命中 0）」，实际 `ExitFree` 3 次、`exit_on_close` 1 次，均在 thinking 块；该条被列为"被源文件直接推翻的错误断言（最严重）"，与另外 2 条一起使 9 条抽检中 3 条判错。

**边界 / 反例**：
- 反向坑是 `subagent-transcript-exec-vs-mention` 的假阳性：thinking / 正文里出现命令名 ≠ 执行过。**存在性按块类型搜，执行性按结构字段判**，别把两件事混起来。
- "thinking 里出现"只证明该概念被考虑过，不等于被结论采纳；本条纠正的是"0 命中"的假阴性，不要顺手升级成"报告结论依赖该词"。
- 前提是该 harness 把 thinking 独立成块（pi / Claude 是）。若某 harness 把 reasoning 混进正文，分块检索前提不成立，需换判据（本条未复验）。
- 本条与 `checker-positive-control-or-negative-void` 属同一类"否定结论不可靠"，但机理不同：那条是检查器正则漏字符，本条是检索范围漏块。

**失败信号（未来命中即该想起本条）**：读到"某词从未出现 / 命中 0"的断言就直接采信；或自己下否定结论时只搜了正文与工具块、没说明检索范围。
