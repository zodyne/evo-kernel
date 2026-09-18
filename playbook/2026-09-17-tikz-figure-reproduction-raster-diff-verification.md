---
id: tikz-figure-reproduction-raster-diff-verification
type: lesson
status: validated
scope: global
domain: latex
tags: [tikz, xelatex, verification, pymupdf, figure-reproduction]
triggers:
  - "把扫描书图/示意图重绘成 TikZ/矢量图，想确认重绘是否忠实于原图"
  - "重绘的矢量图编译通过，但不确定内容/位置/比例是否与原图一致（失败信号）"
  - "需要一条数值化验证闭环来判断矢量图复现精度，而非只看编译是否成功"
  - "用 fitz/PyMuPDF 把编译出的 PDF 渲染回位图做比对"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adbb-beac-7710-933f-0b7fdf4f8cb9
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pgfplots-3d-addplot3-not-addplot, xelatex-tikz-cjk-ecglue-control-spacing, tikz-redraw-align-compare-ink-bbox-anchor]
---

重绘扫描图为可编辑矢量图（TikZ）时，编译通过 ≠ 复现正确，必须把成品渲染回位图、与原图逐像素比对才算验证完成。

为什么：xelatex 能无错编译出一份排版正常但内容位置/比例与原图不符的图，肉眼难以发现微小偏差。本会话对 6 张图统一走「xelatex 编译 → fitz(PyMuPDF) 按 170 DPI 渲染 PDF 回 PNG → PIL 与原图 crop/逐像素比对」的闭环，每张都以 cmp 脚本确认 ok 后才收尾。

反例/边界：比对要对齐坐标（原图 crop 区域 vs 输出 bbox），DPI 太低会掩盖细线偏差；「编译成功」或「看起来像」不算验证。锚点选错会让偏差量虚高：固定 offset（offx=-337, offy=+21.5）对齐时同组曲线 mean=-41.65 / rms=46.88 / max|d|=106.70（看似大面积失真），改用两侧各自墨水 bbox 角做锚点后 max|d|=1.5px——几十像素的「偏差」其实是坐标系错位而非绘制错误；锚点须是两边都清晰可定位的特征（ink threshold 150/175 稳定一致），目测原点做锚点时偏差量不可信。

证据：命令 `xelatex -interaction=nonstopmode -output-directory=tikz tikz/*.tex`（结果 Output written）+ `python3 -c "import fitz; ... for f,dpi in [...170...]"`（结果 ok）+ `python3 -c "def cmp(orig,out,box,path...)"`（结果 ok）。
