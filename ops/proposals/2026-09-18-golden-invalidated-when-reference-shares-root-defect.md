---
id: golden-invalidated-when-reference-shares-root-defect
type: lesson
status: candidate
scope: global
domain: verification
tags: [golden, 验证, 共模误差, common-mode, dimension-anchor]
triggers:
  - "搭建/复用 golden 基线做回归验收"
  - "golden 数据来自参考项目/参考实现，怀疑它本身有错"
  - "三层验证（量纲锚/单级 oracle/物理合理性）全绿但绝对量纲对不上（失败信号：速度尺度差一个固定倍数）"
  - "迁移仓库时决定要不要重建 golden 目录"
  - "发现所有验证层共享同一组外部输入参数"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af3a-aba2-7097-91f3-80f58c344ace
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored, bytes-exact-oracle-gate-for-pipeline-port, doc-selfreported-counts-drift]
---

## 主张

golden 基线的效力以「参照实现与被验实现的**错误不共因**」为前提：若参照项目用了与被验项目相同的错误参数（如同一份错的雷达波形表），golden 会把系统性错误固化成「验收通过」——此时正确动作是把 golden 判死并清除，用「第一性量纲锚 + 单级 oracle」替代，而不是重建 golden。

## 为什么

algommw 实例（2026-09-17 会话取证）：L2 golden 于 2026-07-17 被判死——参照项目与 algommw 用了同一份错误波形参数，golden 速度尺度系统性偏差 4.76×；且三层验证共享同一错误尺度，层间互验（L0/L1/L3 全绿）抓不住这种共模尺度错误。处置是 `data/golden/` 于 07-23 删除、`tests/golden/` 确认为 19 行空壳，迁移研究明确记录「do not rebuild」。教训的方向性：golden 不是越多越稳，参照物本身被污染时 golden 是负资产。

## 反例/边界

- 与 `dual-impl-cross-check-tolerance-grid-anchored` 互补但方向不同：那条讲**没有 golden** 时用数学独立第二实现自证；本条讲**有 golden** 但参照物与被验物共因污染时必须弃用——两实现/两项目若共享同一错误假设，对拍一致同样不证明正确。
- 与 `bytes-exact-oracle-gate-for-pipeline-port` 不同：那条是移植时对已知正确输出做字节级闸门，前提正是 oracle 本身干净；本条是对 oracle 干净性本身提出证伪条件。
- 判死依据必须是**量纲级**的量化证据（固定倍数偏差）加根因链（参数同源），不能靠「感觉不准」。

## 证据

session 01a0af3a 纪要 §6 原文：「L2 golden invalidated 2026-07-17: the reference project used the same wrong waveform params, so golden speed scale was off 4.76×; data/golden/ deleted 2026-07-23 and tests/golden/ was a 19-line empty shell — do not rebuild. Root cause lesson: all three layers shared one wrong scale; internal consistency cannot catch common-mode scale errors.」
