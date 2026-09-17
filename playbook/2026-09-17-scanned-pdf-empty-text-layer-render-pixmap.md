---
id: scanned-pdf-empty-text-layer-render-pixmap
type: lesson
status: validated
scope: global
domain: document-processing
tags: [pdf, fitz, pymupdf, ocr, text-layer, scanned]
triggers:
  - "用 fitz/PyMuPDF 读 PDF 抽文本，get_text() 返回空串"
  - "扫描版书籍/论文 PDF 想抽文字或定位图表"
  - "PDF page_count/rect 正常但正文抽出来全是空（失败信号）"
  - "需要把 PDF 页面内容变成可处理图像（OCR / 图表提取）"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0adbb-be76-7710-933f-0b7c1479badb
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [macos-vision-framework-chinese-ocr]
---

# 扫描版 PDF 无文字层，get_text() 空串，须渲染成位图再处理

**主张**：扫描版 PDF（纯位图、无嵌入文本对象）用 PyMuPDF（`import fitz`）打开后，`page.get_text()` 返回空串，不能靠它抽正文；正确路径是 `page.get_pixmap(dpi=…)` 把页面渲染成图片，再做 OCR 或图像分析（定位图表/文字）。

**为什么**：扫描书/扫描论文的每一页只是一张位图，PDF 里没有文本对象，故 text 层为空。而 `page_count`、`page.rect` 等元数据照常返回，容易误判为「PDF 损坏 / 缺页 / 被截断」而走错方向（比如想去重下、换代理）。

**修法**：先抽 1–2 页 `get_text()` 探空以确认是扫描版；确认后 `page.get_pixmap(dpi=200~400)` 渲染成 PNG，交给 OCR 或 `PIL`/`cv2` 图像处理。

**反例/边界**：文字型 PDF（LaTeX/Word 导出）`get_text()` 正常，无需渲染；只有扫描/图片型 PDF 才空。

**证据**：session 中 172 页扫描书，`d[10].get_text()[:300]` 返回 `''`（页 10），`page_count` 正常返回 172；随后用 `get_pixmap(dpi=200/400)` 渲染页面成 PNG 才继续图提取与 OCR 定位。
