---
id: verify-dispatched-prompt-identical-before-audit
type: lesson
status: validated
scope: global
domain: verification
tags: [dispatch, audit, baseline, transcript, diff, subagent]
triggers:
  - "审计一个被派发出去的子 agent 会话是否违反约束"
  - "只拿到派发词，要在成堆会话 jsonl 里定位主/子两份 transcript"
  - "直接拿主会话里记录的派发词去判子 agent 违规（失败信号：没确认子 agent 收到的指令原文）"
  - "怀疑子 agent 收到的指令与派发者以为的不一致"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e522-725c-a75a-f97a33010dba
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [stamp-baseline-before-review]
---

**主张**：审计被派发的子 agent 是否守约，第一步不是看它干了什么，而是**钉住它实际收到的指令原文**：用派发词里的独特句子 `rg -l` 定位相关 transcript，把两份记录的派发词各自提取落盘、`diff` 确认逐字一致，再拿它当判据。否则整份合规判定可能建立在「派发者以为它说了什么」之上。

**为什么**：主会话里记录的派发词和子会话首条 user 消息是两份独立的落盘副本，手工转述/拼接/截断都会让它们产生差异；判据抄错，后面扫命令、数次数、下结论全都白做。这与 [[stamp-baseline-before-review]] 是同一类前置动作——那条钉的是代码基线 sha，本条钉的是**指令文本基线**，且核对方式是把两个副本 diff 出来。

**证据（切片逐字）**：
- 用派发词里的一句话定位文件：`rg -l '跑嵌套 nvim 会互相干扰' .` → `./2026-09-14T08-56-38-833Z_01a09f21-f8b1-74d6-aeb7-1ea7a469056d.jsonl ./2026-09-16T00-43-09-986Z_01a0a7aa-e522-725c-a75a…`（被审计会话与当前会话同时命中；派发词原句取自只读约束那段文本）。
- 两份提取物逐字比对：`2561 /tmp/dispatch_parent.txt     2561 /tmp/dispatch_sub.txt     5122 total === diff === IDENTICAL`——子 agent 收到的派发词与派发侧记录一致，后续合规判定才有共同判据。

**边界/反例**：切片只留下这段 `wc` + `diff` 输出，**两个文件的提取命令被截断**；「dispatch_parent / dispatch_sub 分别对应派发侧与接收侧」是由文件名与命令上下文推定，未见到提取命令原文。切片也没有给出反例（不一致时该怎么处理），也没验证该方法在 Claude / Hermes transcript 上的字段差异。本条只主张「先核对再判」，不主张 diff 一定为 IDENTICAL。
