---
id: auto-approval-classifier-outage-blocks-bash
type: lesson
status: candidate
scope: global
domain: agent-harness
tags: [harness, tool-approval, auto-mode, classifier-model, deepseek-flash, retry]
triggers:
  - "工具调用被拒，报 auto mode cannot determine the safety of Bash right now（失败信号）"
  - "同一条命令刚才被拒、原样重试就通过"
  - "harness 里 Bash/命令类工具突然大面积执行不了，但命令语法没问题"
  - "配置 auto 审批模式，要评估审批用的小模型不可用时会怎样"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:1363c097-a1c9-4248-a903-814a33facb13
last_verified: 2026-08-13
superseded_by: null
schema_version: 1
---
# auto 审批模式依赖一个小模型：它挂了，命令会被拒，报错却长得像命令有问题

## 主张
工具自动审批（auto 模式）是**靠一个辅助小模型判定命令安全性**的。该模型不可用时，
harness 不是放行也不是降级，而是**直接拒绝执行**，并抛出
`deepseek-v4-flash is temporarily unavailable, so auto mode cannot determine the safety of Bash right now. Wait briefly a...`。
这与命令本身对错无关——**正确反应是原样重试（或等一会再试），不要去改命令、改引号、改路径**。

## 为什么
报错出现在工具调用的位置，形态和"命令失败"一样，很容易触发"我命令写错了"的错误假设，
进而把一条本来正确的命令反复改写（本会话就出现过同一条 `for kv in ... hermes config set ...` 被拒后原样重试即成功）。
更重要的是它揭示了一条架构性事实：**审批链路上的辅助模型是硬依赖，其可用性直接决定 agent 还能不能动手**。

## 证据（本会话命令对照，同一错误至少 7 次）
- `cd ~/.hermes/hermes-agent && for kv in "display.skin claude-code" "display.sections.thinking collapsed" ...`
  → `✗ deepseek-v4-flash is temporarily unavailable, so auto mode cannot determine the safety of Bash right now. Wait briefly a...`
  紧接着**同一条命令**再发一次 → `── set display.skin=claude-code ✓ Set display.skin = claude-code in /Users/zodyne/.hermes/config.yaml ── set display.sec...`
- 同样被拒后重试成功的还有：`grep -n "transcriptGutterWidth..." inputMetrics.ts`、
  `npm test 2>&1 | grep -E "Test Files|Tests|FAIL|✗|×"`、多段 `python3 << 'EOF'` 扫 jsonl 的调用。
- 被拒时**没有任何命令输出**，只有这一行错误——即工具确实未执行。

## 边界 / 反例
- 本条只验证了"被拒 + 原样重试可通过"；**未验证**如何绕过（切换审批模式 / 换判定模型）是否可行或安全。
- 错误文本里的模型名与本机 provider 配置绑定，别的机器上模型名会不同；识别特征是
  `auto mode cannot determine the safety of` 这半句，而不是具体模型名。
- 若重试持续失败，那才是判定模型/上游长时不可用，属于路由与配额问题，不要在此时批量重发命令。

## 失败信号（未来命中即该想起本条）
- 工具报错里出现 `temporarily unavailable` + `cannot determine the safety`。
- 命令零输出、非命令自身的 stderr，且换写法无效、原样重发有效。
