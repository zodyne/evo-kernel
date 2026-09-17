---
id: pgfplots-3d-addplot3-not-addplot
type: lesson
status: validated
scope: global
domain: latex
tags: [pgfplots, tikz, xelatex, 3d]
triggers:
  - "xelatex 编译 pgfplots 报 ! File ended while scanning use of \\pgfflt@readlowlevelfloat"
  - "用 pgfplots 画三维坐标/曲面/三维曲线/三维航迹"
  - "把三维数据点写进 \\addplot 却编译不过"
  - "TikZ/pgfplots 3D 图重绘或复现，xelatex 中途报错"
  - "pgfplots 三维仿真图渲染失败，怀疑 ctex 或 z 轴刻度样式"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad3c-a28f-7710-933f-0b4f234cbcbb
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [tikz-figure-reproduction-raster-diff-verification, xelatex-tikz-cjk-ecglue-control-spacing]
---
pgfplots 画三维图时，三维坐标数据点必须用 `\addplot3[no marks]`，误用 2D 的 `\addplot[no marks]` 会触发 `! File ended while scanning use of \pgfflt@readlowlevelfloat`，编译失败。

复现《群目标跟踪》图7.2（四个目标三维理论航迹）时，pgfplots 用 `\addplot[no marks]` 装载三维坐标，xelatex 报上述「读取低层浮点坐标时文件意外结束」错误。用最小复现 t3d.tex 试了 4 个变体（换 ctex 包 / 换 z tick label style）全部失败，排除中文包和 z 轴刻度样式因素；把 `\addplot[no marks]` 改成 `\addplot3[no marks]` 后编译通过、渲染 OK。

边界：仅当数据是三维坐标（x,y,z）且画在 3D 轴上才用 `\addplot3`；二维图仍用 `\addplot`。
