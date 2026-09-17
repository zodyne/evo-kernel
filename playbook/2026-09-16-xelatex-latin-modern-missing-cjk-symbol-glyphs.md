---
id: xelatex-latin-modern-missing-cjk-symbol-glyphs
type: lesson
status: validated
scope: global
domain: documentation
tags: [xelatex, latex, cjk, chinese-report, missing-glyph, font]
triggers:
  - "xelatex 编译日志报 Missing character: There is no ... in font"
  - "中文 LaTeX 报告里圈码/箭头/特殊符号缺字"
  - "Latin Modern 字体缺 CJK 符号字形导致 PDF 符号缺失"
  - "中文报告编译出 PDF 但个别符号消失（失败信号）"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4ee-6d56-777c-a410-3236022192ef
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [xelatex-section-math-hyperref-texorpdfstring]
---

# xelatex 中文报告：正文非 ASCII 符号在 Latin Modern 缺字形

## 主张

xelatex 中文报告正文里出现圈码 ①②、⇒、⚠、全角箭头等非 ASCII 符号时，主字体 Latin Modern 无这些字形，编译日志报 `Missing character: There is no ① (U+2460) in font [lmroman10-regular]`，PDF 里该符号消失（缺字）。需统一替换成全角括号（①→(1)）、数学模式（⇒→$\Rightarrow$）或有字形的全角字符。

## 证据

- `xelatex` 日志：`Missing character: There is no ① (U+2460) in font [lmroman10-regular]`、`no ⚠ ... in font`、`⇒` 同样缺字。
- 修复后：`圈码换成全角括号 ... 缺字 0`；`替换 '⇒' × 1 ... 缺字: 0`；`把 1 个 ⚠ 换掉（字体缺字形）`。

## 边界

- 与 [[xelatex-section-math-hyperref-texorpdfstring]] 相邻但不同：那条是 hyperref PDF 书签的 `Token not allowed`（数学进不了书签），本条是**正文缺字形**。
- 定位方法：`grep "Missing character" <log>` 即可拿到缺字的 Unicode 码点。
