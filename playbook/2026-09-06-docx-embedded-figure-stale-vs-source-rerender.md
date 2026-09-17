---
id: docx-embedded-figure-stale-vs-source-rerender
type: lesson
status: validated
scope: global
domain: docx
tags: [docx, 嵌入图, LaTeX, 源码脱节, 重渲, 交底书]
triggers:
  - docx 里嵌的图与其 LaTeX/源码脱节、正文与图矛盾
  - 改含嵌入图的 docx 前要不要先重渲图
  - pcf 交底书 media/image1.png 还是老版流程图
  - 图里画的流程与正文写的状态数不一致（失败信号）
  - 需要把 docx 嵌入图与 docs/figures 源码比对
created: 2026-09-06
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-09-06-13-48-47-258-twka
last_verified: 2026-09-06
superseded_by: null
schema_version: 1
related: [docx-batch-edit-verify-by-redump, doc-drift-fix-grep-by-concept]
---

# docx 里嵌的图可能与其 LaTeX/源码脱节：改前先重渲图与源码比对

docx 里嵌的图可能与其 LaTeX/源码脱节：pcf 交底书 media/image1.png 还是两态 KEEP/REJECT 老版，而 docs/figures/patent_flowchart.tex 早已是三态 KEEP/MARGINAL/REJECT，正文也写三态——改这类文档前先把图重渲一遍与源码比对，否则代理人/读者看到的流程和正文矛盾。
