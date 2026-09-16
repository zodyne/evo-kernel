---
id: docx-batch-edit-verify-by-redump
type: lesson
status: candidate
scope: global
domain: docx
tags: [python-docx, batch-edit, verification, contract-review, redump, residual-check]
triggers:
  - "用 python-docx 脚本批量替换合同/报告里的日期、金额、技术参数"
  - "脚本打印了『已保存 / 替换 N 处』就准备交付（失败信号：没有回读）"
  - "多轮修订后担心旧参数、旧日期还残留在表格单元格里"
  - "改完 docx 要确认文件没写坏（能打开、段落/表格/节数没掉）"
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:e9b77b86-b6b5-441e-a133-e72516849e75
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [doc-drift-fix-grep-by-concept, design-review-numeric-recompute-verifies-fix]
---
# docx 批量替换的验收判据是"重新 dump + 旧值 grep 为空"，不是脚本自报的替换条数

## 主张
脚本打印 `已保存 / P97 替换 'X' -> 'Y'` 只证明它走到了自己的替换分支，不证明目标值在文件里被**全覆盖**。
改完必须重新 dump 一份纯文本，做三件事才算完：
① grep 旧值 → 应全空；② grep 新值 → 应在预期段落/表格命中；③ 回读段落/表格/节/字数计数 → 兼作"文件能否正常打开"的结构完好性检查。
表格单元格是最常漏的残留位置（正文改了、表里没改）。

## 为什么
docx 的同一语义值散落在正文段落、表格单元格、页眉页脚多处，替换脚本按段落文本匹配时天然会漏掉结构不同的位置；
而 docx 是 zip 包，就地保存还有写坏结构的风险。"脚本没报错"与"文档改对了"是两件事——
本会话正是靠专门的残留检查才确认第二轮技术基线（10 MHz / 65.2 μs / 500.5 MHz）在合同与评估报告里都清干净了。

## 证据（本会话命令对照）
- 脚本自报：`已保存 CCM…docx / P97 替换 '人民币拾万元整' -> '人民币壹拾万元整' / P76 替换 '于2026年7月31日之前完成' -> '于2026年9月15日之前完成' / 表4…`。
- ① 旧值残留检查：`=== 残留的旧日期(应无7月31日/表内8-31) ===`；第二轮 `=== 残留旧基线参数检查（应全部为空）=== --- 合同: 10 MHz / 65.2 / 500.5 / 500 MHz --- 合同无残留 ✓ --- 评估报告: …`。
- ② 新值命中：`grep -n "每期开具的增值税专用发票" /tmp/contract_after.txt` → `159:P103 [Normal sz14]: （3）乙方应保证每期开具的增值税专用发票合法有效…`；
  `grep -n "本项目整体进度要求" /tmp/report_after.txt` → `85:P62 [Normal]: …2026年9月15日前完成CCM波形与合成处理设计方案…`（旧值 7月31日 已消失）。
- ③ 结构计数回读：`CCM波形…合同…docx: 段落=195 表格=6 节=1 总字数≈9236` / `委外评估报告…docx: 段落=141 表格=6 节=2 总字数≈5957`（两文件均可被 python-docx 正常打开）。

## 边界 / 反例
- 计数回读只能证明"结构没塌 + 能打开"，证明不了版式/字体没变；格式敏感的交付仍需人眼或 Word 打开确认。
- 旧值 grep 要用**语义关键词**而不是整句（本次用 `10 MHz`、`65.2`、`500.5` 这类片段），整句 grep 会因换行/run 切分漏检。

## 失败信号（未来命中即该想起本条）
- 只有脚本 stdout 的"替换 N 处"作为交付依据，没有 after 文件的 grep 输出。
