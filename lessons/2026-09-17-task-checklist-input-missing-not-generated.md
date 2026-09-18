---
id: lesson-task-checklist-input-missing-not-generated
type: lesson
status: candidate
scope: global
domain: data-pipeline
tags: [batch-processing, checklist, manifest, input-validation]
triggers:
  - "接手批量任务，任务书/清单列了 N 个待处理项（页面/文件/ID 列表）"
  - "开工前拿不准清单里每一项是否都已生成对应的输入"
  - "按清单逐个处理时，某项对应的输入文件/页面在数据目录里找不到"
  - "犹豫缺失项是『我漏做了』还是『上游本来就没生成』（失败信号）"
  - "想静默跳过缺失项、或反过来硬找不存在的输入（失败信号）"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0ad4f-cb40-7710-933f-0b581374e4b9
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [verify-numbered-list-full-coverage-by-regex-count]
---
批量任务的输入清单可能与实际已生成的输入不一致——清单里多出的项是「未生成」而非「漏做」，开工前先对账，缺失项标注跳过并报告，不要硬找、也不要静默丢弃。

**为什么**：转写扫描书公式（GroupTracker）时，任务书列了 chunk04 覆盖 p082–p092，但 meta/sheets/ 里实际没有 p083/p084/p087（未出联系表）。若当成「漏做」会浪费时间找不存在的输入；若静默丢弃，产出清单与实际不符，下游对账难。

**边界/反例**：仅适用于「清单由上游计划生成、输入由另一环节生成」的批量场景。若清单即用户口头点名的少量项，缺失更可能是真漏做，需先问清来源而非默认跳过。

**证据**：session:01a0ad4f-cb40-7710-933f-0b581374e4b9 —— 切片里 chunk04 实际 pages 列表 ['082','085','086','088','089','090','091',...] 与任务书页集不符；末条 assistant 明确标注「p083/p084/p087 在 meta/sheets/ 中不存在（未出联系表）」。
