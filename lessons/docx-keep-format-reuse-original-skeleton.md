---
id: docx-keep-format-reuse-original-skeleton
type: lesson
status: deprecated
scope: global
domain: docx
tags: [docx, python-docx, format-preservation, report]
triggers:
  - "生成 docx 要求保留原格式/封面"
  - "把新内容灌进旧 docx 模板"
  - "docx 目录和页码"
  - "两个 docx 内容合并格式不变"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:dd4c9446+b4705404
last_verified: 2026-07-31
superseded_by: skill:docx
schema_version: 1
---

**主张**：「内容更新但格式一字不动」类 docx 任务，正确做法是以原文件为模板骨架改内容，而不是重新排版：直接打开原 docx 替换段落/表格文字，样式（封面表格、标题字号、Table Grid 框线、会签表、页边距）原生继承；目录用真正的 Word TOC 域（打开后 F9 更新），标题编号沿用样式自带多级列表，不手打。

**为什么**：两次独立会话验证：① 评估报告生成，复用原报告底层文件骨架，封面 logo、修订记录、签批表原样保留；② 任务书变更合并，变更后文件是另一套排版（22pt 标题/无框线/单元格前置空段），若按内容源排版就会把错格式带进来——必须以格式源（原文件）为基底灌内容。改动前先存 `.bak.docx` 备份。

**边界**：费用等豁免章节整块锁死不碰；生成后回转（pandoc/LibreOffice 或解 zip）验证结构与可打开性；列数不同的表格不能逐格灌，要按结构映射重建行。

**证据**：2026-07-31 ccm 评估报告会话 + 2026-07-28 任务书变更合并会话，均一次交付通过。
