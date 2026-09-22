---
id: latex-tabularx-conversion-must-flip-end-tag
type: lesson
status: validated
scope: global
domain: latex
tags: [xelatex, tabularx, bulk-edit, build-error]
triggers:
  - "把 \\begin{tabular} 批量替换成 \\begin{tabularx} 后编译报 ! LaTeX Error: \\begin{tabularx} ... ended by \\end{tabular}（失败信号）"
  - "用脚本/字符串替换批量改 LaTeX 成对环境（tabular/table/figure），只换了开始标签"
  - "表格超宽想换 tabularx 自适应列宽，改完 environment 名编译不过"
  - "程序化编辑 .tex 后 xelatex 报环境不配对，不确定哪一半没换"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bdef-64b5-738d-af4a-290ada962882
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [latex-float-h-option-requires-float-package]
---

# 批量把 tabular 转 tabularx：必须同时换掉配对的 \end{tabular}

## 主张

用程序化替换把 `\begin{tabular}` 改成 `\begin{tabularx}` 时，如果只替换开始标签而漏掉配对的 `\end{tabular}`，xelatex 报 `! LaTeX Error: \begin{tabularx} on input line N ended by \end{tabular}` 并中断；把对应的结束标签一起换成 `\end{tabularx}` 后编译通过。

## 证据（session 01a0bdef，wtr10/dsp_research/算法优化设计方案.tex）

- 第一轮替换（注释写明「两个超宽表改 tabularx」）后 `xelatex` 失败，日志出现 `232:! LaTeX Error: \begin{tabularx} on input line 132 ended by \end{tabular}.`
- 下一轮修改后重跑：`xelatex -interaction=nonstopmode 算法优化设计方案.tex >/tmp/t2.log 2>&1; echo "pass2=$?"` → `pass2=0`（编译通过，剩 13 处 Overfull hbox 属列宽问题，随后再单独调表）。
- 收尾复验：`rm -f *.aux *.log ...` 前最后一次构建 `exit=0`、Overfull 降到 10。

## 边界 / 反例

- 同族风险适用于所有成对 LaTeX 环境（table/tabular/figure/itemize…）：批量替换成对环境时一般要成对改写，或在替换后对 environment 名做配对自检。
- 编译通过不等于排版正确：本例 pass2=0 时仍有 13 处 Overfull，说明环境配对只是第一步，列宽仍需单独修（那一步的判断见会话内对比与渲染复核）。
