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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含最小复现（本机 xelatex 3.141592653-2.6 / TeX Live 2026，tabularx v2.12a）：\n\ncd /private/tmp/claude-501/-Users-zodyne-Dev-evo-kernel/2a5c9cfe-7ff2-46f2-800e-c160ffe842a5/scratchpad/vtest && cat > bad.tex <<'EOF'\n\\documentclass{article}\n\\usepackage{tabularx}\n\\begin{document}\n\\begin{tabularx}{\\textwidth}{XX}\na & b \\\\\n\\end{tabular}\n\\end{document}\nEOF\nsed 's/\\end{tabular}/\\end{tabularx}/' bad.tex > good.tex\nxelatex -interaction=nonstopmode bad.tex  >/dev/null 2>&1; echo \"bad exit=$?\"    # → bad exit=1，log 首条: ! File ended while scanning use of \\TX@get@body.\nxelatex -interaction=nonstopmode good.tex >/dev/null 2>&1; echo \"good exit=$?\"   # → good exit=0，产出 good.pdf\n\n注：条目逐字引的 `! LaTeX Error: \\begin{tabularx} on input line N ended by \\end{tabular}` 我单独复现到了——但需文档中另有一处 `\\end{tabularx}`（两表混改时，如 t1=`\\begin{tabularx}...\\end{tabular}`、t2=`\\begin{tabular}...\\end{tabularx}`）才会出现；单表最小复现给出的是 `! File ended while scanning use of \\TX@get@body`。两者都是『环境不配对』硬错误、exit=1，修法一致（补齐配对的 \\end{tabularx}）。
```

**审核给出的修改意见（要点）**：1) 换证据：原证据依赖的三处产物均已不可复跑——/Users/zodyne/Dev/wtr10/dsp_research/算法优化设计方案.tex 已不存在（wtr10 目录在、该 .tex 已删），/tmp/t1.log、/tmp/t2.log 已消失，且切片里首轮修复命令尾部被截断、不能照抄。把证据节改引上面 minimalRepro 的本机自包含最小复现（bad.tex exit=1 / good.tex exit=0+PDF）。\n2) 收窄症状描述：主张本身（批量把 \\begin{tabular} 换成 \\begin{tabularx} 时必须同时换配对的 \\end{tabular}）成立、稳定、可复跑，保留；但不要只写一种报错——单表最小复现下 xelatex 报 `! File ended while scanning use of \\TX@get@body`，而条目逐字引的 `! LaTeX Error: \\begin{tabularx} on input line N ended by \\end{tabular}` 需文档中另有一处 \\end{tabularx} 才出现。建议在触发条件/主张里并列这两种报错（更利召回）。\n3) 修正证据 3 的转写：`rm -f *.aux *.log ...` 实为显式文件名 `rm -f 算法优化设计方案.a

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 「同族风险适用于所有成对 LaTeX 环境（table/tabular/figure/itemize…）：批量替换成对环境时一般要成对改写，或在替换后对 environment 名做配对自检」——由单次 tabular→tabularx 观测升格为『所有成对环境』的通则；切片只覆盖 tabularx/table 一例（内容方向正确、『一般』有兜底，但确属超出切片的一般化，应标为通则而非本例实测）。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
