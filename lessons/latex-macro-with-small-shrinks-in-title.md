---
id: latex-macro-with-small-shrinks-in-title
type: lesson
status: deprecated
scope: global
domain: latex
tags: [latex, xelatex, macro, fontsize, title, code]
triggers:
  - "自定义的 \\code / \\path 类宏内部带了 \\small / \\footnotesize 等字号命令"
  - "把这类宏用在 \\title / \\author / \\section 标题里"
  - "xelatex 编译全绿，但 PDF 里标题/作者行的字异常缩小（失败信号）"
  - "写 LaTeX 报告标题页，想给标题里的命令名/文件名套等宽宏"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:eaa269a8-34b2-4abf-a08f-1dd23a6ff138
last_verified: 2026-08-03
superseded_by: skill:latex-tikz-figures
schema_version: 1
related: [xelatex-missing-character-renders-blank, figure-readability-has-no-log-signal]
---

**主张**：内部带字号命令（`\small` 等）的自定义宏（如 `\code`）**不能用在 `\title` / `\author` / 章节标题里**——标题本身是大字号，再叠 `\small` 会把文字缩得极小，且 xelatex 编译不报警，只有渲染出来才看得见。

**证据**（ucm221 faf_offline 进展报告，2026-08-03）：`progress_report.tex` 的标题/作者处用了带 `\small` 的 `\code` 宏，渲染 PNG 目检发现字被缩得极小。补丁注释明确记录：「标题/作者不要用 \code（它带 \small，在标题字号下会被缩得极小）」，改掉后重新编译 + pdftoppm 渲染确认修复。编译日志全程无相关警告——又是「编译绿 ≠ 排版对」的一例。

**做法**：标题/作者/section 标题里需要等宽效果时，用不带字号的 bare `\texttt`，或另定义一个不含字号命令的标题专用宏；正文里的 `\code` 保留 `\small` 没问题。

**边界**：问题只在「宏内字号 × 标题大字号」叠加时出现；正文、表格、caption 里用带 `\small` 的宏是正常做法，不要因本条把 `\small` 从宏里去掉。检测手段依赖渲染目检（见 `figure-readability-has-no-log-signal`）。
