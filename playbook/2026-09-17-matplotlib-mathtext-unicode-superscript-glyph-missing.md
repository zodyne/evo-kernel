---
id: matplotlib-mathtext-unicode-superscript-glyph-missing
type: lesson
status: validated
scope: global
domain: plotting
tags: [matplotlib, mathtext, unicode, glyph, plotting]
triggers:
  - "matplotlib 标签/标注里写了 unicode 上标字符（如 ⁿ U+207F）报 Glyph missing 警告"
  - "matplotlib 数学文本想写上标，用了 unicode 上标字符而不是 ^ 语法"
  - "matplotlib 图里某些 unicode 数学符号缺字、UserWarning 刷屏"
  - "写 matplotlib 标签时上标如 (−1)ⁿ 显示异常或缺字"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a3f4-bbd4-763d-a251-9f1065aa3a2a
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [matplotlib-cjk-font-order-first-silences-missing-glyph]
---

matplotlib 的标签/数学文本里，unicode 上标字符 ⁿ（U+207F）在当前字体里没有字形，会报 `Glyph 8319 (\N{SUPERSCRIPT...}) missing from current font` 警告；上标要用 mathtext 语法 `^n`（如 `(−1)^n`），不要写 unicode 上标字符。

为什么：跑 `run_demo.py` 报 `run_demo.py:657: UserWarning: Glyph 8319 (\N{SUPERSCRIPT...}) missing from current font`；用 `sed -i '' 's/(−1)ⁿ/(-1)^n/g'` 把 unicode ⁿ 替换为 `^n` 语法后警告消失、标签正常。

反例/边界：这与 CJK 缺字不同——CJK 靠换字体解决，unicode 上标字符则是「字体里根本没有该字形」，换字体不一定有用；最稳的是改用 mathtext 的 `^` 语法，让渲染器自己排版上标。
