---
id: fma-contraction-invalidates-bitwise-acceptance-gates
type: lesson
status: validated
scope: global
domain: build-system
tags: [浮点, 编译优化, 验收闸门, cmake, fma]
triggers:
  - "做『输出与旧实现逐位一致』类的 C/C++ 移植验收"
  - "新构建链迁移（CMake 重写/编译器升级）后担心浮点优化开关丢了"
  - "逐位对拍/MD5 级闸门莫名失败，差在浮点累积结果上（失败信号）"
  - "把 -ffp-contract=off / 禁 fast-math 从旧构建文件搬到新构建系统"
  - "字节级 golden 闸门在新编译器下失效，排查无头绪"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af3a-aba2-7097-91f3-80f58c344ace
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [bytes-exact-oracle-gate-for-pipeline-port]
---

## 主张

凡验收判据是「逐位一致」（字节级对拍、MD5、memcmp 级 golden 闸门）的 C/C++ 代码，构建配置必须同步携带 `-ffp-contract=off` 且禁用 fast-math——编译器 FMA 收缩允许在优化等级不变的前提下改变浮点结果位型；构建链迁移时这类开关不迁移，闸门即静默作废。

## 为什么

algommw 把此作为硬约束并写进验证策略（2026-09-17 会话取证）：「-ffp-contract=off needed for any "unchanged output" claim」（naming.md §5）；迁移研究在「Byte-identical-capable for C++」一节明确把「-ffp-contract=off plus no fast-math must survive in the new CMake, otherwise the gate is void」列为字节级闸门成立的前置条件。仓库内已有正反实证：ADR 0005 记录双驱动字节级闸门「caught a real bug」（开关在时有效），而部分逐位锚（如 golden CSV）已因浮点域差异不可用。这属于「闸门存在性检查」类坑：test 全绿 ≠ 闸门有效，位型承诺先于对拍逻辑成立。

## 反例/边界

- 只约束「逐位一致」级判据；统计容差/网格级判据（如 `dual-impl-cross-check-tolerance-grid-anchored` 的 FFT 网格级容差）不受 FMA 影响。
- 与 `bytes-exact-oracle-gate-for-pipeline-port` 互补：那条定义「移植后要与 oracle 逐字节对拍」，本条给出该闸门在编译层面的失效模式与前置开关清单。
- x86 与 ARM（含 NEON）默认 FMA 收缩行为不同，跨架构移植时尤其易触发。

## 证据

session 01a0af3a 纪要 §2「Measured, not assumed」条目与 §6 逐位闸门前置条件原文（见上文引），均出自会话内读取的 naming.md §5 / CLAUDE.md / afm761 study §4 原文。
