---
id: image-ascii-raster-visual-inspection-without-vision
type: lesson
status: candidate
scope: global
domain: document-processing
tags: [pil, numpy, ascii, image-inspection, no-vision-channel]
triggers:
  - "没有看图能力/视觉通道不可用，但要确认裁剪图或截图里的内容"
  - "agent 只能读文本输出，手里却是图片需要判断内容（失败信号）"
  - "想在会话里直接看公式小图的字形结构，而不是只靠尺寸和墨水统计"
  - "把灰度图二值化转 ASCII 栅格打印出来目视检查"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad8d-77d9-7710-933f-0b6fdbb1e7d0
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [pil-row-scan-verifies-terminal-render, scanned-formula-crop-cross-check-source-page-render]
---

无视觉通道时，把灰度图按阈值二值化、逐行映射成 `#`/空格 的 ASCII 栅格打进 stdout，可以直接在文本通道里目视辨认字形与版面结构；先 crop 到目标小区域（必要时放大）再看，配合墨水密度（H/W/ink）数值通道互为印证。

**为什么**：agent 对图片只能读文本输出，肉眼看不见像素；但二值化后的栅格是纯文本，字形差异（加粗 V vs 普通 V、ε 的下标形态）在栅格里直接可辨，让「看图」变成会话内可完成的动作。本任务用它配合 ink 密度统计，区分了加粗与非加粗符号、核对了下标细节。

**证据**（命令↔结果佐证）：切片多条 `python3 <<'EOF'` 对 p065-01 / p066-05 / p072-06 / pg66-066 / pg112-112 等图输出 ASCII 栅格，如「== P」与「(5.7) eps subscript region」「(5.9) eps+sub : y1250-1300 x1060-1140」后均跟栅格正文；同一批脚本同时报出 ink 密度（如 P bold ink=0.619 vs V ink=0.161），栅格（定性看形）与 ink 值（定量比对）两条通道并用完成粗体甄别。

**边界**：只适用小裁剪区域——整页（1912×2786）转栅格不可读，必须先 crop；对灰度阈值敏感（本任务 thr 试过 140/150/200，结果不同）；输出宽度受终端限制，宽公式要分段裁看；它是「看形状」不是「量化」，量化结论要靠 ink 密度等数值通道。
