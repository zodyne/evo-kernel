---
id: narrow-int-index-field-wraparound-silent
type: lesson
status: candidate
scope: global
domain: c-embedded
tags: [c, uint8, overflow, wraparound, ddm]
triggers:
  - "审查/实现 C 数据结构里用 uint8_t 等窄整型存索引、子带号、fold 号等值域可能 ≥256 的字段"
  - "DDM/DDMA fold 表或子带映射表对不上，某个 bin 的值凭空变成 0"
  - "改了 numSubbands / numTx / 子带数后，下游 doppler 静默算错但无任何报错（失败信号）"
  - "怀疑整型存储宽度不够导致静默回绕（回绕后值仍落在合法范围，看不出异常）"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a6b9-89c5-7353-8a3d-42e7d5d82a48
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [adc-wraparound-silent-unlike-saturation-clip]
---

主张：C 结构体里用 `uint8_t`（或其它窄整型）存索引/序号类字段（DDM fold 索引、子带号），值域 ≥256 时静默回绕（256→0），下游拿到错值且全程无任何报错。

为什么：`uint8_t` 上限 255。algommw `core/include/core/types/radar.h:65` 把 DDM fold 表 `xFold[...]` 定成 `uint8_t`，而 :59 声明语义是 `0..numSubbands-1`；当 numSubbands 从 6 突变到 384、perSub 从 128 改到 2，fold 索引可达 256，实测 `xFold[100][0] = 0`（真实 fold = 256）——256 被 uint8_t 截断回绕成 0，最终 xDoppler 静默算成 +0.000 m/s。

反例/边界：`adc-wraparound-silent-unlike-saturation-clip` 讲的是 ADC 溢出「计数」本身回绕（int16），此处坑不同——是「存储字段宽度」不足以容纳索引值域；且回绕后值仍落在 0..255 合法范围、看不出异常（不同于钳位到边界的显式截断）。仅当字段值域能超过类型上限时才触发；若值域被别处硬性限制在 255 以内则无此坑。

证据链接：`/tmp/slice.txt` 行 20（`eWaveformValidate(subbands=384, chirps=768, perSub=2) = 0 (0=eOk)`）、行 69（`xFold[100][0] = 0 (真实 fold = 256)` → `xDoppler=+0.000 m/s`）、行 87（`radar.h:65` `uint8_t xFold[...]`，:59 语义 `0..numSubbands-1`）。
