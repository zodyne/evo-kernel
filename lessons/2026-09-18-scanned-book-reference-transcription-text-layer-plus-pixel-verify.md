---
id: scanned-book-reference-transcription-text-layer-plus-pixel-verify
type: lesson
status: candidate
scope: global
domain: ocr
tags: [ocr, reference-transcription, scanned-book, pdf-text-layer, pixel-verify]
triggers:
  - "精确转写扫描书 / 扫描 PDF 的参考文献或书目页（密排小字英文）"
  - "OCR 初稿在密排小字英文上错误率高，需要逐条核对而人工重打太慢"
  - "PDF 文本层有内容但拿不准哪些词被 OCR 读错了"
  - "扫描书转写交付前不确定处太多，想收敛成一份可复核对的不确定清单"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad8f-3d86-7710-933f-0b7531a957ce
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [scanned-pdf-empty-text-layer-render-pixmap, macos-vision-framework-chinese-ocr]
---

# 主张

精确转写扫描书的参考文献时，先读 PDF 已有的带坐标文本层（blocks.jsonl，含 pdf_page + 块坐标）拿初稿，再对不确定的词逐个裁剪原图对应 band 区域做像素级比对，而不是重跑 OCR 或盲信初稿。

# 为什么

300 dpi 扫描书的密排小字英文文献，OCR 错误率偏高（实测 ~7% 词错误）。但 PDF 文本层已经是带坐标锚点的初稿：逐条读 blocks.jsonl 拿文本，对拿不准的词裁出原图 band 区域比对像素，就能把「盲信初稿」收敛成「一份显式标注的不确定清单」留人审，而不是整页重打。

# 证据（命令级）

会话 41 条命令几乎全是「读 blocks.jsonl 拿初稿 → PIL 裁剪 band 区域 → 像素比对」，最终产出 refs_c.json 共 64 条（en 55 / zh 9），其中 34 条显式标不确定（编号 + 具体词）。

# 边界 / 反例

- 前提是 PDF 有可用文本层；若 get_text() 返回空（纯扫描无文字层），走 scanned-pdf-empty-text-layer-render-pixmap（渲染成图 + OCR），不要读 blocks.jsonl。
- 与 formula-region-crop-upscale-before-vision-transcribe 不同：那条讲「公式小图裁剪 + 放大后交视觉模型」，本条讲「文本引用用文本层 + 像素比对」，对象与手段都不同。
