---
id: pymupdf-getpixmap-dpi-must-be-integer
type: lesson
status: validated
scope: global
domain: python-lib
tags: [pymupdf, fitz, pixmap, dpi, integer-args]
triggers:
  - "用 PyMuPDF/fitz 把 PDF 页面渲染成位图"
  - "按目标像素尺寸反推 dpi 值"
  - "get_pixmap(dpi=...) 传小数直接抛异常（失败信号）"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adbb-be40-7710-933f-0b7b5ed7f46f
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
---

# PyMuPDF `get_pixmap(dpi=...)` 的 dpi 必须传整数，按像素目标反推时要 int 取整

**主张**：`page.get_pixmap(dpi=...)` 的 dpi 参数不接受浮点数，传小数（如 `dpi=286.6`）直接抛异常；按"目标像素宽 / 页面 pt 宽 × 72"反推 dpi 后要 `int(...)` 再传入。

**为什么**：把 PDF 页渲染到与已有扫描位图同尺寸做比对时，自然要按比例反推 dpi（本例 956/150dpi 推出 286.6），小数顺手就传进去了；PyMuPDF 的 dpi 形参要求整数。

**做法**：`dpi = int(round(target_px / page.rect.width * 72))`；渲染后打印 `pix.width/height` 核对与目标尺寸的偏差，残余 1-2px 比例差在拼接比对时用归一化/仿射对齐吸收，不再追求 dpi 精确复现。

**证据**：同一页面连续两次调用，唯一差异是 dpi 值：`dpi=286.6` 抛 Traceback（异常详情在会话切片中被截断），`dpi=287` 正常出图（1829×2665）。
