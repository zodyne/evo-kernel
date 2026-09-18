---
id: spc865-frame-counter-tt-phase-not-always-1
type: fact
status: candidate
scope: project:spc865
domain: radar-data-format
tags: [spc865, bin, frame-header, frame-counter, alignment]
triggers:
  - "用帧头 TT 字节做 SPC865 帧编号/对齐/丢帧检测，假设文件第一帧 TT=1"
  - "按 TT==1 判断文件或批次起始帧，发现部分文件从 2 开始（失败信号）"
  - "检查 63 个 .bin 的 TT 序列，大多数文件报 MISMATCH（失败信号）"
  - "要把多帧数据按帧号排序、拼接或做跨文件相位对齐"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7de-9a07-7719-ba82-31efaa0ea03c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

**主张**：SPC865 帧头的 `TT` 字节是 1..4 循环的帧计数器，但**相位不固定**：63 个文件里只有 11 个的 TT 从帧 0 起严格按 1,2,3,4 循环，其余 MISMATCH；例如 100 帧的 `865_0801_2025-10-09-11-40-04_0.bin` 序列是 `[2, 3, 4, 1, 2, ...]`，末帧 TT=1。用 TT 做丢帧/对齐/起始帧判断前必须先测该文件的序列相位，不能假设首帧 TT=1。

**为什么**：TT 是采集侧自由运行/分段重置的模 4 计数器，采集起点不同就会带不同相位；「首帧 TT=1」只在少数文件成立。若拿 TT==1 当「批次起点」或「第 1 帧」的判据，会在 52/63 个文件上判错，且错得静默——序列看上去依然规律（2,3,4,1,2…），只是整体偏了一格。

**证据（本会话命令 ↔ 结果）**
- 全库相位检查：`== TT sequence check ==   files whose TT = 1,2,3,4 repeating starting at frame 0: 11 / 63    MISMATCH ('20251009_865单板暗箱…`。
- 单文件序列：`865_0801_2025-10-09-11-40-04_0.bin   nfr=100  TT[:5]=[2, 3, 4, 1, 2] TT[last]=1`。
- 帧头字节 dump 印证 TT 位置：`frame header bytes: aa 55 01 00 00 00 55 aa`；报告头部写作 `bytes AA 55 TT 00 00 00 55 AA`。
- 帧头变体清单也显示 TT 取多个值：`(('aa550100000055aa', 5), ('aa55020000005…`。

**边界 / 反例**
- TT 只有 4 个取值，长文件里会绕圈（100 帧绕 25 圈），所以它**不能**唯一标识帧号，只能做 mod-4 的连续性/相位检查；跨帧唯一 ID 要用「文件内偏移 // 帧长」。
- 本会话只测出「63 个文件里 11 个从 1 开始」，没有定案各文件相位差的原因（采集起点不同 vs 其它重置逻辑）。
- 11/63 这个比例是 2026-09-16 时点上、`/Users/zodyne/Dev/SPC865` 全库的实测值；新增采集批次后需重跑该检查，不能把 11/63 当常数。
