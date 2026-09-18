---
id: accent-mark-ink-profile-classification
type: playbook
status: candidate
scope: global
domain: document-processing
tags: [scanned-book, latex-transcription, diacritics, hat, tilde, connected-components, formula-audit]
triggers:
  - "判断扫描公式字母头顶的记号是 hat、tilde、dot 还是 bar"
  - "变音符与主字形墨水粘连，整块连通域数不出来"
  - "转写稿把 \\dot 误写成 \\tilde、或漏掉变音符（失败信号）"
  - "X̂/X̃/ż 这类上加记号字母要逐个确认记号种类再写 LaTeX"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad64-2a2e-7710-933f-0b6734543245
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [image-ascii-raster-visual-inspection-without-vision, formula-region-crop-upscale-before-vision-transcribe]
---

判定字母上方变音符（hat/tilde/dot/zdot/bar）用「墨水行剖面 + 主字形上方独立簇的几何量」流程：先用连通域/行剖面把顶部记号从主字形分离，量记号簇的位置（y 范围）、横向延展与簇数，把候选收敛到一二种后，再裁剪放大 + ASCII 栅格做最终目视确认——用数值把「猜记号」变成可复算的定位。

**为什么**：变音符在 300dpi 扫描上只有几个像素高，单靠放大图目测容易漏判/混判（\dot 写成 \tilde、ż 漏点）；程序定位 + 几何量化后每个记号的核对过程可写进审计 reason。本会话 p126-02 的 ż_{pq} 下标串、p053 的 X̃/X̂ 均按此流程逐个核对后才改写转写。

**证据**（命令↔结果）：
- `seg.py` 连通域输出把顶部记号与主字形分离：`{'i': 0, 'x0': 118, 'y0': 0, 'x1': 132, 'y1': 93, ...}`（y0=0 即上方记号带独立成簇）；
- zdot 子块程序定位后裁剪放大 + ASCII 栅格复核：`magick ... -crop 22x34+485+90 -resize 1600%`，输出 `--- sub#1 of first zdot [486, 94, 504, 122] ---`；
- bold_audit.json p053-01 reason：X̃、X̂ 等「已在 300 dpi 原图上放大 4x 与 ASCII 描边核对」。

**边界**：记号「种类」的最终判读仍含人的目视成分（ASCII 栅格打出来由人读）；程序量化的是簇的位置/延展/数量，作用是把候选收敛而非全自动分类。若记号与主字形完全粘连连通域分不开，退化为行剖面（找主字形上方的独立墨水行带）。
