---
id: scanned-formula-crop-cross-check-source-page-render
type: playbook
status: candidate
scope: global
domain: document-processing
tags: [scanned-book, transcription, validation, pdftoppm, fidelity]
triggers:
  - "转写扫描书公式/图表，裁图放大后仍拿不准内容"
  - "公式转写完成后，想确认内容与原图一致，而不是只确认能编译通过"
  - "编译验证只证明语法对，需要给转写内容忠实度做交叉验证"
  - "扫描区域裁剪框不清晰或灰度低，放大也看不清（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad56-93d1-7710-933f-0b652a58f12a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [scanned-book-formula-latex-compile-validation, scanned-book-reference-transcription-text-layer-plus-pixel-verify, tikz-figure-reproduction-raster-diff-verification]
---

扫描书公式/图表区域转写拿不准时，用 pdftoppm 按页渲染原始 PDF 源页（高 dpi）做交叉验证，把放大后的裁剪图与源页对照，而不是只盯着放大后的裁剪图猜内容。

**为什么**：裁剪图来自版面分析、本身可能裁偏或灰度低；转写对不对不能只靠「能编译」（那只证明语法正确）。重新渲染源页能拿到未经版面分析处理的原始像素，用于核对裁剪框内内容的忠实度。

**证据**：切片里多条 pdftoppm 命令渲染源页——`-f 59 -r 300`（p59hi）、`-f 77/-f 116/-f 137/-f 155 -r 130` 等，产物落到 /tmp/misfit/；末条助手汇报明确「另渲染原 PDF 的 p59/p77/p116/p137/p155 原页做交叉验证，据此确定」10 区域分类与转写。

**边界**：渲染源页是「人工对照」级验证，不是数值化 diff（要硬 diff 见 tikz-figure-reproduction-raster-diff-verification，但那针对矢量重绘）。「据此确定」属助手自报告，切片里没有逐页 diff 结果，故「渲染→保真度提升」的因果为推断；verified_by 记 command 仅因渲染动作与对照步骤有命令+结果佐证。
