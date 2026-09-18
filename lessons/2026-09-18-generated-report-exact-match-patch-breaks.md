---
id: generated-report-exact-match-patch-breaks
type: lesson
status: candidate
scope: global
domain: doc-editing
tags: [markdown, patch, exact-match, assertion, line-range, verification]
triggers:
  - "对已生成/已改过几轮的长 Markdown 报告用脚本做『整段原文精确匹配再替换』"
  - "补丁脚本报 assert old in s 或自定义 AssertionError（如 tree miss），但你以为那段文本没动过（失败信号）"
  - "批量替换里某几处打印 MISS 后继续执行、文件行数几乎没变（失败信号：静默漏改）"
  - "一轮修订要改 5 处以上，且上一轮刚改过相邻区段"
  - "想知道补丁到底生效了几处、有没有被静默跳过"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7de-9a07-7719-ba82-31efaa0ea03c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [docx-batch-edit-verify-by-redump, string-replace-outside-block-corrupts-body]
---

**主张**：对已经改过几轮的派生文档，用「整段原文精确匹配 → 替换」是脆弱闸门：匹配串会在上一轮修订后漂移，失败有两种形态——硬 `AssertionError`（`assert old in s`、自定义 `tree miss`）和打印 `MISS` 后继续执行的静默漏改。应改为先 dump 目标区段的行号+`repr` 确认当前文本，再按行号区间替换（或整节重写/重新拼装），并把 `wc -l` 前后差值当作每轮改动的落地核对。

**为什么**：长报告每轮修订都在移动/合并文本（本会话合并了两张 9.2 表、删了分隔线、重排了目录树），上一轮写死的匹配串与当前内容不再逐字相同；`assert old in s` 会直接中断，而柔性实现只打印 `MISS` 就继续，导致「脚本跑完了」但缺了几处改动。行号替换不依赖文本内容，只要拿到当前行号快照就能命中。

**证据（本会话命令 ↔ 结果）**
- 硬失败 1：`python3 /tmp/patch_report2.py` → `Traceback … File "/tmp/patch_report2.py", line 31, in <module>  assert old in s  ^`（AssertionError）。
- 硬失败 2：内联脚本用 `old = """```\nMatlabSpc865/data/\u251c…` 匹配目录树 → `AssertionError: tree miss`。
- 软失败：一批替换输出 `MISS ## 12. Performance — is a per-frame vectorised numpy reader  720 -> 716`——该处未匹配，其余生效，脚本仍以成功姿态结束。
- 有效做法：先 dump 行号+repr（`s=open(p).read().splitlines(); for i in range(334,352): print(i+1, repr(s[i]))` → 拿到 `335 '**Non-.bin capture artifacts** …' 336 '' 337 '```' …`），再按索引替换（`L=open(p).read().splitlines()  # replace lines 338..349 (1-indexed) => idx 337..348` → 输出 `338 MatlabSpc865/data/ 339 ├── CS 1.1.9采集数据.rar …`，落地成功）。
- 行数核对：每次改动打印前后行数 `720 -> 716`、`716 -> 706`、`706 -> 690`、`lines: 659`——行数不变即说明这轮基本没落地。
- 对照：同一会话中文件化的补丁脚本 `python3 /tmp/patch_report.py` 能正常执行（`body lines: 426 tail lines: 32`），说明问题不是工具坏，而是匹配串与当前文本漂移。

**怎么做**
1. 改前先 `repr` dump 目标区段（带 1-based 行号），确认锚点当前长什么样；
2. 按行号区间切片替换，或把整节重写成独立文件后 `cat` 重新拼装；
3. 替换函数要返回命中计数，`MISS` 必须当失败处理（记录区段名，不能只 print 后继续）；
4. 每轮改完 `wc -l` 前后对比；行数没变就回去查匹配。

**边界 / 反例**
- 行号会随后续编辑移动：要在同一轮内用同一份行号快照，跨轮必须重新 dump 定位。
- 精确匹配本身不是错的——失败集中在「匹配串取自上一轮版本」；一次性生成的短文档用精确匹配完全够用。
- `wc -l` 只能证明「有改动」，证明不了「改对了」；内容正确性仍需回读目标区段（可与 `docx-batch-edit-verify-by-redump` 的重新 dump 纪律配合）。
