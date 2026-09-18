---
id: same-origin-constant-missed-update
type: lesson
status: candidate
scope: global
domain: code-duplication
tags: [constant, header, drift, board-expansion]
triggers:
  - "改一个常量/宏的值，但它在多个头文件里都有 #define"
  - "扩容/升配（单板→双板）后某处数值上限对不上，怀疑只改了一份"
  - "grep 某个宏名发现多个定义，拿不准哪份是权威"
  - "看到注释写 '与 XX 同源/保持一致'，怀疑两处值已不同步"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad51-f327-77c1-a593-51b9e8bdab94
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [markdown-doc-anchor-count-drift]
---

同一个常量/宏在多个"同源"头文件里重复定义时，扩容或改值必须逐处同步——漏改其中一份会潜伏到后续版本才暴露。

为什么：algommw 的 MAX_ADC_SAMPLES 在 sensor.h 与 radar.h 两处"同源"定义；F1 双板扩容时只改了 sensor.h、漏改 radar.h，到 F3 才补。

证据：会话 grep `DOA_SCAN_MAX_CELLS|MAX_ADC_SAMPLES|MAX_DOPPLER_BINS` 命中 `core/include/core/types/radar.h:13` 注释原文："sensor.h 的 MAX_ADC_SAMPLES 同源(F1 双板扩容时曾漏改此处,F3 补)。"

边界/反例：只适用"同一逻辑常量被复制到多处"的场景；两处若语义独立、数值恰好相同则不算此坑。文档里硬编码的数字/行号与代码对不上是另一类问题（见 related 条目 markdown-doc-anchor-count-drift）。
