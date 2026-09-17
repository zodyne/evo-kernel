---
id: xelatex-tikz-cjk-ecglue-control-spacing
type: lesson
status: validated
scope: global
domain: latex
tags: [xelatex, tikz, ctex, cjk, xeCJK]
triggers:
  - "xelatex+ctex 编译含中文的 TikZ 图，中英混排间距不对/有多余空隙"
  - "TikZ 图里放中文文字，想控制 CJK 与拉丁字符之间的 glue"
  - "编译通过但图内中文与英文/数字之间出现异常间距（失败信号）"
  - "写含中文的 TikZ 图，需要配置 xeCJK 的 glue 设置"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adbb-beac-7710-933f-0b7fdf4f8cb9
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [tikz-figure-reproduction-raster-diff-verification, pgfplots-3d-addplot3-not-addplot]
---

含中文的 TikZ 图用 xelatex+ctex 编译，除 `\usepackage{ctex}` 外还需 `\xeCJKsetup{CJKecglue={}}` 控制 CJK 与拉丁字符间的自动 glue，否则图内中英混排间距异常。

为什么：xeCJK 默认在中英文/数字边界插入 glue，在紧凑的 TikZ 图里会产生多余间距。本会话先在 fig6-2 上手动追加 `\xeCJKsetup{CJKecglue={}}`，再循环把该设置补进其余 5 个 .tex，之后统一重编译 6 张图全部 ok。

反例/边界：此设置关的是 CJK-Latin 边界 glue，与「缺字形」问题是两回事（见 xelatex-latin-modern-missing-cjk-symbol-glyphs）；仅当图内含中文混排才需要，纯英文 TikZ 不涉及。

证据：命令 `python3 - <<EOF ... s.replace('\\usepackage{ctex}','\\usepackage{ctex}\n\\xeCJKsetup{CJKecglue={}}')`（结果列出 6 文件 done）+ 后续 `xelatex` 循环编译 fig6-2..fig3-4 全部 ok。
