---
id: tikz-figure-overflows-page-silently
type: lesson
status: deprecated
scope: global
domain: latex
tags: [tikz, xelatex, figures, silent-failure]
triggers:
  - "画 TikZ 流程图/架构图，或改已有图的节点与连线"
  - "生成的 PDF 里图超出页宽 / 流程图跑到页边外"
  - "LaTeX 编译没报错但图排版不对"
  - "给 tikzpicture 的节点设了 minimum width 仍然排不下"
  - "xelatex 日志里出现 Overfull \\hbox 不知道该不该管"
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:dc63fb24-b5f6-455e-87c6-6bfc029de1eb
last_verified: 2026-07-28
superseded_by: skill:latex-tikz-figures
schema_version: 1
---

TikZ picture 宽于 `\textwidth` **不会报错**，只在 `.log` 里留一条 `Overfull \hbox`，图照样出血到页边外。

`minimum width` 是**下限不是宽度**：节点内容比它宽时会静默撑大，所以"每个节点都写了 3cm"不等于图宽可控。配合 `right=1.5cm of x` 这类相对定位，总宽变得无法心算，只能渲染出来才知道。

硬证据（`docs/user-manual.tex`）：4 个 `minimum width=3cm` 的节点 + 3 个 1.5cm 间距，因 `frontmatter/atomize/link` 这种无断点长串把节点撑到 ~4.2cm，实际 19.4cm，而 `\textwidth=455.24pt`（16cm）。log 报 `Overfull \hbox (95.61577pt too wide) in paragraph at lines 432--433`——行号指向 `\end{tikzpicture}`/`\caption`，不是出问题的那条 `\draw`。

判读经验：>50pt 基本是图或表出血到页边；<15pt 多是正文段落的排版余量，可忽略。

做法：
1. `grep -n 'Overfull \\hbox' doc.log` 取行号（TeX 指向构造末尾，要向上扫）；`grep -n 'textwidth=' doc.log` 取预算。
2. 用绝对坐标 `\node (a) at (3,2)` 而非相对定位，并把宽度核算写进 tikzpicture 上方的注释：
   `图宽 ≈ Σ节点宽 + Σ间距`，`节点宽 ≈ max(minimum width, 最长行 + 2×inner sep)`，`inner sep` 默认每侧 0.3333cm。
3. 收窄手段优先级：改短/折行节点文案 → 降一档字号 → 缩间距 → 改拓扑。`scale=` 放最后——它缩坐标但不缩节点文字，会把上面的算术全部作废。

反例/边界：长串如 `frontmatter/atomize/link` 没有断点，TeX 不会替你折行，`text width` 也救不了，只能自己用 `\\` 手动断。
