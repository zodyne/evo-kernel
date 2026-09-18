---
id: ink-rowband-projection-locate-transcription-crops
type: playbook
status: candidate
scope: global
domain: document-processing
tags: [scanned-book, transcription, pil, numpy, row-projection, layout]
triggers:
  - "转写扫描书整页/多页条目，需要把每条内容定位成逐条裁剪框"
  - "扫描页条目间距小、坐标手抄太慢或容易错位"
  - "裁出的图一条内容跨两段或多一段（失败信号：逐条转写对不上编号）"
  - "要从灰度扫描页自动产出 band 坐标再逐条放大确认"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad8f-3d13-7710-933f-0b711b58db30
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [formula-region-crop-upscale-before-vision-transcribe, scanned-book-reference-transcription-text-layer-plus-pixel-verify, scanned-region-ink-density-classify-matrix-vs-figure]
---

转写扫描书的整页密排条目（参考文献/书目等逐条结构）时，用 PIL+numpy 对页面灰度做行投影（每行墨迹像素计数、超阈值记为占用行、把连续占用行聚成 band），自动产出每条内容的 y 区间裁剪框，再逐条 crop+放大确认，而不是肉眼估坐标。

**为什么**：逐条结构的条目间距小、数量多（本任务 3 页 53 条），手抄坐标既慢又易错位；行投影把「第 N 条在哪」变成可复算的数值信号，产出的 band 坐标直接作为逐条裁剪与放大确认的输入。

**证据**（命令↔结果直接佐证）：
- 多页跑「逐行墨迹计数 → 连续占用行聚类 band」：p161_b1、p162_b2、p163_b0、p163_b1、p163_b2、p162_b0、p162_b1、p161_b2、p161_b0、p163_b2、p164_b0 等均报出 `(start, end)` 行带序列（如 p161_b1: (14,45),(80,115),(151,177),…）；
- 随后 13+ 条 crop+resize 放大命令全部基于这些 band 坐标产出 /tmp/zoom 确认图；
- 末条校验 `refs_a.json` n=53（en 46 / zh 7）、ids 连续 1..53=True、显式 uncertain 16 条。

**边界**：行带数=条目数的前提是「一条目=一连续墨迹带」；条目内空行、图版混排会碎带或多带，需按页微调阈值与 gap（本任务按页分批跑、逐页核对 band 数与条目数后才进入裁剪）。只做定位，不做内容判断；转写忠实度另走像素比对/存疑标注（见 related 的管线兄弟条）。
