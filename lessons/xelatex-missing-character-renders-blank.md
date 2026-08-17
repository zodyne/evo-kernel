---
id: xelatex-missing-character-renders-blank
type: lesson
status: deprecated
scope: global
domain: latex
tags: [xelatex, cjk, 中文报告, 图检]
triggers:
  - "xelatex 编译通过、准备交付中文 PDF 报告前"
  - ".log 里出现 Missing character 警告（失败信号）"
  - "PDF 里某些中文字符渲染成空白，但编译没报错"
  - "CJK 文字出现在没配中文字体的环境（数学/tt/特定字体组）里"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:583c96aa-69cd-41b3-926b-4f72d4d7c7f5
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [figure-readability-has-no-log-signal, tikz-figure-overflows-page-silently]
---

xelatex 编译退出码正常 ≠ 字都渲染了：`.log` 里的 `Missing character` 警告意味着该字符在 PDF 中是**空白**（常见原因是 CJK 文字落进了没配中文字体的字体环境），编译器不报错，肉眼才发现。

会话证据：`latex-figure-check.sh` 对 `doa_array_layout_report.tex` 报 `!! [2] Missing character (renders BLANK — often CJK inside ...)`；同一份还有 `Overfull \hbox (83.1pt too wide)` 的段落级溢出版面。

交付前检查链：grep .log 的 `Missing character` 与大值 `Overfull`（>15pt 影响版面），再 `--render` 出 PNG 逐页目检。编译绿只是第一步。
