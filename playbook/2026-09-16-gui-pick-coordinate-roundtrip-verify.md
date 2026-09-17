---
id: gui-pick-coordinate-roundtrip-verify
type: lesson
status: validated
scope: global
domain: gui-testing
tags: [pick, 拾取, 坐标映射, roundtrip, 往返核验, pyside6, 测试]
triggers:
  - "写/审 GUI 图像坐标↔数据坐标的拾取（pick）映射"
  - "单元测试单边断言绿，但实际点选坐标错位/顺序颠倒"
  - "给拾取/反算加往返（发→反算回）核验判据"
  - "数据坐标（range/velocity 等多字段）时怀疑顺序被交换"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7da-1c77-7719-ba82-31e9d9d40735
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [2026-07-28-qmatrix4x4-data-returns-column-major-tuple]
---

GUI 拾取映射的单边断言会漏掉坐标顺序错位（如 (range, velocity) 被交换），因为单边测试可能恰好对一个方向成立。要做「发→反算回」的往返核验：对每个单元（含四角与中心）正向发出坐标、再反算回 (range, velocity) 精确还原才算通过。

实测：拾取坐标顺序 bug 单边绿但往返错位（单元(r=200,d=40)→发出(558.311m,-11.363m/s)→反算回(r=334,3)❌），修复后 5 单元往返精确✅。
