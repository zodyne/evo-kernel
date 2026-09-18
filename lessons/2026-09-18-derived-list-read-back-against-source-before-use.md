---
id: derived-list-read-back-against-source-before-use
type: lesson
status: candidate
scope: global
domain: tooling
tags: [batch-processing, acceptance, scripting, set-drift]
triggers:
  - "从文件系统派生一份批量清单（ls/glob 出的 capture 批次、待处理文件列表）再逐个处理"
  - "批量任务收尾要证明『这批就是我名下该处理的全部』"
  - "处理条数对不上目录里的文件数，怀疑清单漏了条目（失败信号）"
  - "把中间清单存 /tmp 反复使用，拿不准它还全不全"
  - "搬运/整理类任务交接时被问批次覆盖是否完整"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae53-5888-764c-a77e-517e2c4c9b6b
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [acceptance-command-path-must-match-file-layout-table, docx-batch-edit-verify-by-redump]
---

## 主张

凡从文件系统**派生**出来的批量清单（先 ls/glob 存下来、后续一直照着干的那份），用之前和收尾时都必须与源做一次集合级回读对账（catalog 分区计数 + `ls` 计数 + `comm` 差集），因为派生那一刻清单就可能已经漏项，且后续流程不会自己发现。

## 为什么

派生清单与源文件集是两个独立状态，搬运/整理过程本身只回放清单内容，不会暴露清单少了谁。本会话（01a0ae53，74 条 inbox capture 批量转提案任务）里，agent 早期把自家批次列表存到 `/tmp/capbatch_ad` 后一路使用；直到收尾对账才发现缺口——`awk -F'\t' '$2=="inbox"{print $1}' /tmp/cat_full.tsv | wc -l` → 74、`ls inbox/*.md | wc -l` → 74，两计数一致坐实源集合规模，`comm -23` 求差集后额外列出 `capture-2026-09-08-*`、`capture-2026-09-09-*` 等不在派生批次里的 id。若不做这次回读，漏掉的条目会静默留在 inbox，任务却以「全部完成」收尾。

## 反例/边界

- 与 `docx-batch-edit-verify-by-redump` 不同：那条是对**已改内容**做全覆盖回读（替换有没有漏），本条是对**清单派生本身**做集合对账（清单有没有漏项）——一个管替换覆盖率，一个管派生完整性。
- 与 `acceptance-command-path-must-match-file-layout-table` 不同：那条是设计评审期对两份规约做交叉核对，本条是执行期对自己的中间产物对账。
- 回读必须落到集合级（计数 + 差集），只数「我处理了 N 条」自证不了完整；另外清单存 `/tmp` 跨时间复用时，对账要重跑而不是信任旧结论。

## 证据

session 01a0ae53-5888-764c-a77e-517e2c4c9b6b（evo slice 硬证据切片，「命令 ↔ 结果」第 16/17 条）。
