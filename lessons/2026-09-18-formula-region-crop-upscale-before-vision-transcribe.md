---
id: formula-region-crop-upscale-before-vision-transcribe
type: playbook
status: candidate
scope: global
domain: document-processing
tags: [ocr, vision, pil, latex, scanned-book, formula-transcription]
triggers:
  - "把扫描书/扫描 PDF 里的公式图片转写成 LaTeX 或文本"
  - "公式小图直接交给视觉模型转写，识别差/乱码"
  - "要从页级联系表里逐个裁剪公式区域再转写"
  - "扫描书公式转写，拿不准裁剪框和放大倍数怎么取"
created: 2026-09-18
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: session:01a0ad4f-cacc-7710-933f-0b554d93c284
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related:
  - scanned-pdf-empty-text-layer-render-pixmap
  - macos-vision-framework-chinese-ocr
---

# formula-region-crop-upscale-before-vision-transcribe

## 一句话主张

转写扫描书里的公式时，先用 PIL 把每个公式从页级联系表/页面里裁剪出紧致包围盒，
再 resize 放大（约 2-6 倍，目标宽约 2300-2900px）后交给视觉模型转写，
而不是把原尺寸小图直接喂给模型。

## 为什么

联系表上的公式原始裁剪框高度只有几十到两百多 px（如 390×70、850×110、1450×180），
直接转写可读性差。会话内 10+ 条命令一致采用 crop→resize 放大的形态，
最终 8 页 52 个区域（equation 50 / matrix 1 / text 1）全部转写完成并写入 chunk02.json。

## 反例 / 边界

- 放大倍数不是统一值，随裁剪框原始尺寸浮动（实测 2-6 倍），不是固定 scale。
- 「放大能提升识别率」这一步是流程推断，切片里没有 A/B 或「失败→放大→成功」的对照证据，
  只有该流程被一致采用并最终完成的证据。技术动作本身（crop→resize）由命令直接佐证，
  故 verified_by 记 command；放大有效性属推断，已在正文标注。
- 仅对公式/图表小图的转写场景成立；正文 OCR 引擎选型不在本条范围。

## 证据

slice 命令↔结果 15 条，其中 10+ 条为
`Image.open('meta/sheets/p0XX.png').crop((x1,y1,x2,y2)).resize((2xxx, ...))` 形态，例如：
- `crop((860,760,1250,830)).resize((2340,...))` —— 390×70 → 6x
- `crop((700,850,1550,960)).resize((2550,...))` —— 850×110 → 3x
- `crop((100,420,1550,600)).resize((2900,...))` —— 1450×180 → 2x

末条 assistant 汇报：`chunk02 done: 8 页, 52 个区域 (equation 50 / matrix 1 / text 1)`。
