---
id: research-only-session-empty-slice-zero-distill
type: lesson
status: candidate
scope: global
domain: experience-engineering
tags: [evo-kernel, evo-slice, distill, reflector, hard-evidence, research-session]
triggers:
  - "后台 Reflector 对已结束会话跑 evo slice 做蒸馏"
  - "evo slice 输出『命令 ↔ 结果（0 条）』且写/改文件段为空（失败信号）"
  - "被蒸馏的会话是纯搜索/调研任务（只走 searxng 等 MCP 工具，无 bash、无文件改动）"
  - "想拿末条 assistant 的结论文本当硬证据写提案"
  - "切片证据撑不住任何主张，纠结要不要硬凑一条"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fb08e-8091-7f0e-9f1e-4286c1528fca
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [evo-slice-normalize-toolname-case-and-path-field]
---
# 纯调研会话的 evo slice 天然是空切片（0 命令、无写文件）：证据为空就零产出，不得拿 assistant 结论文本编提案

## 主张
`evo slice` 只捕获 bash 命令与写/改文件动作；一个**只走搜索/MCP 工具、无 bash、无文件改动**的纯调研会话，切片会表现为"命令 ↔ 结果（0 条）+ 写/改文件为空"——这是预期现象，不是会话没干活，也不是解析器坏了。Reflector 遇到这种切片：唯一硬证据是"发生过一次调研"，而调研结论只存在于末条 assistant 文本里（可能还被截断），**不构成可验证证据**。正确处置是零产出（只做完 injected 对账就收尾），禁止把 assistant 的结论文字改写成经验提案。

## 为什么
蒸馏的证据等级要求 command/test/human 佐证。assistant 的结论文本三者都不是：它不可复验、可能截断、且无法区分"真搜到的"与"模型编的"。把这种文本蒸馏入库，等于给经验库注入未验证断言，污染后续注入通道。空切片本身倒是一个有价值的过程信号：它标记了"这类会话不产生可蒸馏素材"，识别它可以直接收工，省下硬编提案造成的评审噪音。

## 证据（本会话切片硬证据）
- `evo slice --session .../2026-07-30T01-05-56-881Z_019fb08e-...jsonl` 输出：`命令 ↔ 结果（0 条）`，`写/改文件` 段为空。
- 同一切片：首条 user 为 `搜索分析有没有pal类似的mcp项目`，末条 assistant 以 `搜完了，信息量足够。结论如下：` 开头并引用具体外部事实（GitHub 项目名、~12k stars）——证明调研确实发生，但全程无一条命令进切片，且结论文本在切片里被截断。
- 即：工作量存在 ≠ 可蒸馏证据存在；本会话据此只产出本条过程性提案，调研内容本身未蒸馏。

## 边界 / 反例
- 空切片**也可能**是解析 bug（per-harness 工具名大小写/路径字段未规整，见 related 条目）：若会话里明确有大量 bash/edit 活动而切片为 0，那是解析器漏块，不是本条情形，应去修 parser。区分点：首条 user 与末条 assistant 是否显示该会话本就只是搜索/对话。
- 调研会话若夹杂可验证动作（跑了命令、写了报告文件），对应片段仍可正常蒸馏，不适用零产出。
- 本条不主张"调研结论一律无价值"——若人（用户）在会话里明确认可了结论，可按 verified_by: human 评估；仅 assistant 自述不算。

## 失败信号（未来命中即该想起本条）
- 切片显示 0 命令 + 无写文件，而你在逐字解读末条 assistant 文本试图"抢救"一条经验。
- 提案的 verified_by 想填 command，但翻遍切片找不到任何命令↔结果对。
- 蒸馏输出里出现以"据 assistant 结论可知"为唯一依据的条目。
