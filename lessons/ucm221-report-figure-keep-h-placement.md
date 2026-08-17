---
id: ucm221-report-figure-keep-h-placement
type: lesson
status: deprecated
scope: project:ucm221
domain: latex
tags: [ucm221, latex, figure-placement, user-preference]
triggers:
  - "改 UCM221 中文 LaTeX 报告的 figure 环境浮动参数"
  - "想把 \\begin{figure}[H] 改成 [htbp]/[ht] 让 LaTeX 自动找位置"
  - "报告图和正文引用顺序对不上，想靠浮动参数修排版"
  - "用户拒绝了把 [H] 改成 [htbp] 的编辑（失败信号）"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:eaa269a8-34b2-4abf-a08f-1dd23a6ff138
last_verified: 2026-08-03
superseded_by: skill:ucm221-weekly-report
schema_version: 1
related: []
---
# UCM221 LaTeX 报告的 figure 保持 [H] 精确占位，不要擅自改成 [htbp]

## 主张

该项目的中文汇报类 LaTeX 报告里，`figure` 环境用 `[H]`（float 宏包精确占位）是用户认可的排版方式。不要以「LaTeX 最佳实践」为由擅自改成 `[htbp]` 浮动——图必须跟在引用它的段落原地，顺序乱了读者会对不上号。

## 证据

- 会话中一次把 `\begin{figure}[H]` 改成 `\begin{figure}[htbp]` 的编辑被用户当场拒绝（"✗ The user doesn't want to proceed with this tool use"），该改动未落地，后续多轮编译继续沿用 `[H]`。

## 边界

仅适用于该用户的汇报/报告类文档；若是用户明确要求修浮动体排版或换文档类，另当别论——但先问再改。
