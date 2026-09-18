---
id: transcription-compile-gate-not-semantic-correctness
type: lesson
status: validated
scope: global
domain: document-processing
tags: [transcription, audit, ocr, latex, quality-gate, sampled-review]
triggers:
  - "转写只有编译门全绿，想知道语义正确率，要一个可证伪的数字"
  - "视觉模型转写的公式/文本交付前做抽验，逐符号核对怎么组织"
  - "能编译 ≠ 语义正确：编译门 0 失败仍查出转写错误（失败信号）"
  - "要设计转写审计的抽样方案并落盘样本清单与逐条 verdict"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad8d-77d9-7710-933f-0b6fdbb1e7d0
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [scanned-book-formula-latex-compile-validation]
---

视觉模型读图→LaTeX 的转写质量，只过语法闸门（xelatex 全量编译通过）不能下结论；要拿到可证伪的准确率，必须做固定样本量的逐符号人工核对审计：先落盘抽样清单（audit_sample.json），逐条对照原图判 verdict，结果落盘（audit_result.json）并输出结构化 error 分类。

**为什么**：编译门只证明 LaTeX 语法合法。本次审计在「283 条 0 编译失败」的基础上，30 条抽样仍查出 3 条语义错误（correct 27 / error 3 / uncertain 0，即 90% 逐符号准确率）——例如 p076-07（式 2.117）「字母认错 + 分母漏下标」，这类错误编译照样通过。没有逐符号审计，这 10% 错误会被「编译全绿」掩盖。

**证据**（命令↔结果佐证）：
- 抽样落盘：`meta/latex/audit_sample.json`（30 条，含 page/id/tags/img/kind/latex 字段，`len(d)`=30）；
- 逐条核对产物：`meta/latex/audit_result.json`（切片「写/改文件」清单唯一落盘文件）；
- 末条 assistant 汇报：`audit done: 30 条 —— correct 27 / error 3 / uncertain 0`，`entries: 30 sample: 30 missing: [] extra: []`，并逐一列出 3 条 error 的错误类型（字母认错/分母漏下标等）。

**边界**：30 条是抽样不是全量（全书 283 条），给出的是估计值而非证明；逐符号人工核对成本高，适合抽验/交付前质检而非日常流水线；error 分类依赖核对者对原书扫描件的判读，uncertain 桶要保留（本次恰为 0）。
