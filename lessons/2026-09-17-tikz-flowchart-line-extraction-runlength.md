---
id: tikz-flowchart-line-extraction-runlength
type: lesson
status: candidate
scope: global
domain: tikz-redraw
tags: [tikz, flowchart, image-analysis, run-length, scanned-book]
triggers:
  - "把扫描书里的框图/流程图重绘成 TikZ"
  - "框图连线横竖看不清、不确定是实线还是虚线"
  - "框线坐标靠目测，重绘后布局与原图对不上"
  - "重绘的框图连线位置或虚线样式与原图不一致（失败信号）"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adbb-be40-7710-933f-0b7b5ed7f46f
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
---

# 框图重绘的连线用二值化 + 行列游程扫描数值化提取，不靠目测

**主张**：把扫描书框图（流程图）重绘成 TikZ 时，框线/连线不要目测描点，先对扫描位图二值化，按行/按列做暗像素游程扫描，直接量出每条横线/竖线的坐标区间、实线 vs 虚线（长游程断口）、线宽（连续暗行数），把结果当 TikZ 坐标写图。

**为什么**：框图全是水平/垂直线段与规则框，是最容易数值化的图形；目测抄坐标误差大且不可复算，而游程扫描输出就是像素坐标，可直接换算进 TikZ。

**做法**（本会话临时脚本套路，用完即删）：
- 横线：`np.where(d[y])` 逐行找暗像素游程，`minlen` 过滤短噪声；竖线同理按列。
- 实线 vs 虚线：游程内断口间距小且周期出现 → 虚线（`_dashdetect`：gap 参数分辨）；长连续游程 → 实线。
- 框完整性：对疑似框边做 coverage 走线（沿整条线统计暗像素占比，`_trace`/`_solidfrac`），占比 1.0 为完整边、0.2-0.9 为虚线/部分边。
- 阈值不合适先调二值化阈值再调游程长度（本例 a<140 漏检浅线，改 a<170 后虚线全出）。

**边界**：只适用于轴对齐的直线元素；斜线、曲线、箭头形状不适用（曲线另有曲线数字化条目）。线宽用连续暗行/列数估，抗锯齿边缘会让宽度偏大 1-2px。

**证据**：会话内对 fig7-5/fig7-10/fig2-4/fig7-17 四张框图实测：`_segdetect`（游程≥80/100 横竖线）、`_dashdetect`（gap=9 分辨虚线段）、`_trace`（coverage=1.00 实线 vs 0.9/0.75 虚线）、`_solidfrac`（竖线段占比打印）；四张图重绘后逐元素复核与原图一致。
