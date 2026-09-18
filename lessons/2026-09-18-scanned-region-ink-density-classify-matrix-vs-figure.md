---
id: scanned-region-ink-density-classify-matrix-vs-figure
type: playbook
status: candidate
scope: global
domain: document-processing
tags: [ocr, scanned-book, formula, matrix-detection, pil, numpy, layout-analysis]
triggers:
  - "版面分析把扫描书里的公式区误判成插图，需要甄别哪些是真公式、哪些是矩阵"
  - "一个扫描区域拿不准是矩阵、公式还是插图，想用程序定量判断而非肉眼猜"
  - "扫描件里矩阵区域被版面分析当成图片漏掉，公式转写批量漏矩阵（失败信号）"
  - "要给版面分析误判的区域补做 equation/matrix/figure 分类"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad56-93d1-7710-933f-0b652a58f12a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [formula-region-crop-upscale-before-vision-transcribe, scanned-book-formula-latex-compile-validation]
---

版面分析把扫描书区域误判为「插图」后，用 PIL/numpy 对该区域逐行/逐列统计墨水密度，据此定量判断它是矩阵（行带等宽且均匀）、插图（稀疏）还是公式（密集不规则），而不是靠肉眼放大猜。

**为什么**：扫描书的版面分析对「公式 vs 插图」判定不可靠——本任务 11 个区域被误判成插图、实际大多是公式/矩阵。逐行墨水密度扫描能把「矩阵」这种结构特征变成可判定的数值信号：矩阵的列/行带呈现等宽、均匀的墨水分布，插图稀疏、公式密集不规则。

**证据**（命令↔结果直接佐证）：
- p59-f01 区域被拆成「matrix col x=380..1100 / left vector x=100..300 / G matrix x=1160..」三个子结构，并报出各自 x 区间与墨水行范围；
- 「6x6 last col / 6x6 col2-3」定位矩阵元素列位置；
- 末条输出「rows: [1,1,1,1,1,1] uniform / rows: [6,6,6,6,6,6] uniform」判定等宽行带。
- 最终落盘 meta/latex/misfit.json：10 区域 = equation 3 / matrix 6 / figure 1。

**边界**：依赖灰度阈值（本任务 th=140、行间距 gap=3）与图像质量，阈值需按图调；只辅助分类，不替代转写本身。它与 formula-region-crop-upscale-before-vision-transcribe（裁+放大交视觉转写）和 scanned-book-formula-latex-compile-validation（编译验语法）是同一管线的前置分类步与后置验证步。
