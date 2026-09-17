---
id: macos-vision-framework-chinese-ocr
type: lesson
status: validated
scope: global
domain: ocr
tags: [vision-framework, ocr, macos, swift, 中文扫描件]
triggers:
  - "在 macOS 上给中文扫描 PDF/扫描书做 OCR"
  - "pytesseract/tesseract 不可用或中文识别差，要换 OCR 引擎"
  - "需要 OCR 输出带坐标+置信度的逐行结果喂给布局分析/公式检测"
  - "扫描书转 markdown，需要一个能落盘的正文 OCR 主引擎"
  - "本机不想额外装 OCR 依赖，想用 macOS 系统自带能力"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad3c-a28f-7710-933f-0b4f234cbcbb
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [scanned-pdf-empty-text-layer-render-pixmap]
---
macOS 上给中文扫描件（无文本层 PDF）做 OCR，用系统自带 Vision framework（`VNRecognizeTextRequest`）写一个几十行的 Swift 工具，可直接输出逐行 `{t,x,y,w,h,c}`（文本 + 归一化坐标 + 置信度）JSONL，无需安装 tesseract/pytesseract，可作为扫描书转 markdown 的正文 OCR 主引擎。

本机 pytesseract、ocrmac 均 ModuleNotFoundError，tesseract CLI 虽在但最终采用 Swift Vision framework（vocr2.swift）：对 86MB 中文扫描书 172 页输出 6256 行、135897 字符，中文识别正确（如「第一章绪论」），且带坐标+置信度，直接喂给下游布局分析（分块、公式/图题检测）。

边界：只适用 macOS 本机；输出是逐行不是段落，需自行按 y 坐标聚合成段落；数学公式/符号识别差，公式需另用公式模型（如 rapidocr）。
