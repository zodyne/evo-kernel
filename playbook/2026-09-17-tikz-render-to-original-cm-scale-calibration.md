---
id: tikz-render-to-original-cm-scale-calibration
type: lesson
status: validated
scope: global
domain: latex
tags: [tikz, pymupdf, dpi, unit-conversion, figure-reproduction]
triggers:
  - "把编译出的 PDF 渲染回位图与原图比对，两边像素坐标对不上"
  - "渲染回位图比对时元素整体错位，怀疑标尺/DPI 不统一（失败信号）"
  - "需要从渲染结果量取 TikZ 图元素的图内坐标来改 .tex"
  - "pt 转 px / px 转 cm 换算，standalone PDF 带 6pt border"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adbb-be00-7710-933f-0b79e52433fb
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [tikz-figure-reproduction-raster-diff-verification]
---

TikZ 重绘图与原图做像素比对前，先把编译出的 PDF 渲染换算到与原图相同的物理尺度（本会话统一为 100 px/cm ≈ 254 dpi），元素坐标按 `px_per_cm = 渲染宽px / (PDF宽pt / 72 × 2.54)` 实测（得 100.03），再按 `(px_bbox − px_origin) / px_per_cm` 换算；同尺度下量出的中文标签/连线位置即可与原图逐一对齐、直接指导 .tex 修改。

**为什么**：standalone PDF 自带 6pt border、渲染 DPI 又是自选的，两侧像素坐标系天然不一致；不先统一尺度，量出的偏差全是换算噪声。本会话按 254 dpi 渲染 fig1-2 得 px per cm 100.03，同一尺度下原图「跟踪维持」wide 框 (880,1079,240,319) 与 TikZ 渲染量得 (899,1059,245,299)，偏差在数像素级，可定位到具体节点标签。

**边界**：`getbbox` 返回 np.int64 时直接打印/比较会混入 `(np.int64(1023), ...)` 浮点垃圾，换算前转 int；`dpi=100/2.54` 这种「每厘米 dpi」直觉写法会渲染出 39 dpi 小图（本会话两次报错都在换算上），正确做法是先定 px/cm 目标再乘 2.54 得 dpi。

**证据**：`python3 -c "import numpy as np, fitz; # 100 px/cm -> 254 dpi; d=fitz.open('tikz/fig1-2.pdf')..."` → 结果 `render px 1419 513 / px per cm 100.02890315245816 / found bbox px 890 1049 222 326 / in cm from bottom 2.2193...`；`...跟踪维持 wide: (880, 1079, 240, 319)`（原图量测）；`...im.crop((330,70,500,300))...` → ok；两次失败 traceback：`pm=d[0].get_pixmap(dpi=100/2.54*1)` 与 cm_crop 脚本 line 7。
