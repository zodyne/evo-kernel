---
id: latex-float-h-option-requires-float-package
type: lesson
status: validated
scope: global
domain: latex
tags: [xelatex, float, table-placement, build-error]
triggers:
  - "xelatex 编译报 ! LaTeX Error: Unknown float option `H'（失败信号）"
  - "table/figure 想用 [H] 原地精确占位，编译中断"
  - "从别的 .tex 抄 [H] 用法，新文档导言区没加载 float 宏包"
  - "改了 .tex 后构建 exit=1，日志把 H 当作未知 float 选项"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bdef-64b5-738d-af4a-290ada962882
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [latex-tabularx-conversion-must-flip-end-tag]
---

# [H] 精确占位要 \usepackage{float}：否则 Unknown float option `H'

## 主张

`table`/`figure` 环境里用 `[H]`（原地不浮动）时，若文档没加载 `float` 宏包，xelatex 直接报 `! LaTeX Error: Unknown float option 'H'` 并 exit=1；在导言区补上 `\usepackage{float}` 后同一文件编译通过（exit=0）。

## 证据（session 01a0bdef，wtr10/dsp_research/算法优化设计方案.tex）

- 报错：`xelatex -interaction=nonstopmode -halt-on-error 算法优化设计方案.tex >/tmp/tex1.log 2>&1; echo "exit=$?"` → `exit=1`，日志 `236:! LaTeX Error: Unknown float option 'H'.`
- 修复：用 python 字符串替换在导言区补 `\usepackage{float}`（该命令回显 `added float`），随后 xelatex 两次编译 → `exit=0`。
- 复验：修后日志只剩 Overfull \hbox 告警（表格列宽问题，另见 tabularx 转环境一条），不再有 float 选项错误。

## 边界 / 反例

- 报错只针对 `H` 这类 float 宏包扩展的大写选项；`[h]`/`[htbp]` 等标准选项不需要 float 宏包。
- 切片未展示导言区原文与完整 .log，本条只覆盖「报错 → 加宏包 → 编译通过」的可复现链，不展开 float 宏包的内部机制。
