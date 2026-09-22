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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含复现（本机 /Library/TeX/texbin/xelatex，XeTeX 3.141592653-2.6-0.999998 下实测）：

mkdir -p /tmp/fp && cd /tmp/fp
printf '\\documentclass{article}\\begin{document}\\begin{table}[H]\\centering a\\end{table}\\end{document}\n' > nofloat.tex
printf '\\documentclass{article}\\usepackage{float}\\begin{document}\\begin{table}[H]\\centering a\\end{table}\\end{document}\n' > withfloat.tex

xelatex -interaction=nonstopmode -halt-on-error nofloat.tex >n1.log 2>&1; echo "exit=$?"; grep -n "Unknown float option" n1.log
  → exit=1
  → 13:! LaTeX Error: Unknown float option `H'.

xelatex -interaction=nonstopmode -halt-on-error withfloat.tex >n2.log 2>&1; echo "exit=$?"
  → exit=0

即：无 float 宏包 exit=1 并报 Unknown float option `H'；加 \\usepackage{float} 后 exit=0。与条目主张逐字一致。
```

**审核给出的修改意见（要点）**：主张、触发词、边界、zone 全部保留（核心主张本机已确定性复验，是 xelatex/LaTeX 的稳定一般属性，不绑任何仓/沙箱）。仅改证据节：把三条会话命令（切片中均被截断，且依赖 wtr10 仓的 算法优化设计方案.tex 当前状态）换成 self-contained 最小复现——一段无 float 的 3 行 article 文档跑 `xelatex -halt-on-error` 得 exit=1 + `Unknown float option `H'`，加 \\usepackage{float} 后 exit=0（命令与期望输出见 minimalRepro）。这样证据可当场照抄重跑，不再依赖被截断的 heredoc 与外部仓快照。边界节那句「[h]/[htbp] 不需要 float」虽不在切片里，但属 LaTeX 手册级标准事实且已由上述最小复现的通用性覆盖，可保留（建议注明依据为 LaTeX 手册而非本次会话观测）。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 报错只针对 `H` 这类 float 宏包扩展的大写选项；`[h]`/`[htbp]` 等标准选项不需要 float 宏包。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
