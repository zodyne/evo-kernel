---
id: bold-vs-italic-stroke-width-metric
type: playbook
status: candidate
scope: global
domain: document-processing
tags: [scanned-book, latex-transcription, bold, stroke-width, pil, numpy, formula-audit]
triggers:
  - "审计扫描书公式转写里 mathbf 标没标对，要判断字形是黑体还是斜体"
  - "两种字体形态的水平笔画只差 2-3px，粗看放大图判不出粗细"
  - "粗体漏标：状态向量/矩阵被转写成斜体、\\mathbf 缺失（失败信号）"
  - "要把黑体/斜体判断变成可复算的数值指标，而不是肉眼定夺"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad64-2a2e-7710-933f-0b6734543245
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [formula-region-crop-upscale-before-vision-transcribe, image-ascii-raster-visual-inspection-without-vision, scanned-region-ink-density-classify-matrix-vs-figure]
---

判断扫描公式里一个字母是黑体（粗体）还是斜体（普通），用笔画宽度统计替代肉眼：二值化后逐行量字形内横向 run 长度，取中位数/p75 并按字高归一化（nsw），粗体呈 6–8 px 实心笔画、细体呈 2–3 px 骨架，页内对照即可稳定区分。

**为什么**：粗体/斜体在扫描件上只差几像素笔画宽度，直接看渲染图易误判；本任务 14 条已转写公式初版 11 条黑体漏标。把判据变成 nsw 数值后可复算、可写进审计记录：本会话最终修正 11 条（p053-01、p055-09、p078-08 等），bold_audit.json 每条 reason 都引用笔画宽度证据。

**证据**（命令↔结果）：
- `sw2.py`：`CAL p053 X(bold) {'n_ink': 94, 'stroke_med': 6.0, 'stroke_mean': 4.9, 'stroke_p75': 6.0, ...}`，同页斜体下标 k、p 仅 2–3 px 细线；
- stem 量测：p053 U BOLD stem=8.40px h=44 stem/h=0.1909；p078-07 Y BOLD stem=7.88 vs 同式细体 f_it stem=3.78、T ital stem=3.40；
- 落盘 `meta/latex/bold_audit.json`：14 条、changed 11 条，reason 写明「笔画核心均为 6-8 px 实心（同页斜体 k 为 2-3 px 细线）」。

**边界**：nsw 单指标区分度不足时会翻车（本例粗体 U nsw≈0.17–0.19 vs 细体 U≈0.14，差距不大），必须叠加三个校准：①同页已知斜体字形做页内基准 ②跨页对比先用共享字形做页间校准（见 related）③与同书已入库邻式的 mathbf 写法一致性核对（本会话对照 chunk00 邻式 2.11 的 \mathbf{X}、\mathbf{\Phi}）。
