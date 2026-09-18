---
id: count-only-acceptance-gates-miss-value-drift
type: lesson
status: candidate
scope: global
domain: verification
tags: [验收, 闸门, 计数, 回归, value-drift]
triggers:
  - "给流水线回归设计验收判据，考虑用帧数/点数/条数等计数兜底"
  - "「通过/失败」类布尔闸门覆盖不了的质量回归排查"
  - "算法参数改了但输出数量级不变，怀疑判据是否够敏（失败信号：闸门常绿）"
  - "验收通过但下游拿到的是退化结果，回头找闸门盲区"
  - "评审他人测试方案时判断计数类断言的判别力"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af3a-aba2-7097-91f3-80f58c344ace
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [doc-selfreported-counts-drift, bytes-exact-oracle-gate-for-pipeline-port]
---

## 主张

只校验数量的验收闸门（如 EXPECTED_BOARDS 的帧数/检测数/航迹点数）对「计数不变、数值退化」类回归结构性失明——它判别的是产量不是质量，不能作为唯一验收层，必须与逐值比对（array_equal / 逐点容差）组合使用。

## 为什么

algommw 把此写成成文教训并纳入迁移研究（2026-09-17 会话取证）：「EXPECTED_BOARDS count-only gates (documented: they miss value drift at constant counts — COMPASS/CLAUDE)」。仓库分层验证中计数闸门只是最外层粗筛，逐值保证由 npz 8 数组 array_equal（`--save-path`）与单级 memcmp 断言（`unit_fft_mixed`）承担。危险模式在于计数闸门常绿造成的虚假信心：CFAR/测角参数漂移、量化步长错误、点云字段退化都可能完全不改帧/点计数。同类盲区在该仓库还有实例：F7 修复合规后 track pts 1051→991，计数变了，但若改动恰好保持计数则只有逐值闸门能抓到。

## 反例/边界

- 本条是判别力问题，不是计数漂移问题：`doc-selfreported-counts-drift` 管「文档自报数字与实际脱节」，本条管「拿数字当验收判据本身的灵敏度上限」。
- 计数闸门不是不能有，而是不能单独存在：作为廉价的粗筛层 + 逐值层兜底是本仓库实证有效的组合。
- 与 `bytes-exact-oracle-gate-for-pipeline-port` 互补：那条提供逐值闸门的构造方法（oracle 对拍），本条论证为什么计数层替代不了它。

## 证据

session 01a0af3a 纪要 §6「Cannot gate」原文（见上文引，出处 COMPASS/CLAUDE.md）；§5 基线表显示仓库同时维护计数锚（EXPECTED_BOARDS 1000/24748/991 等）与逐值锚（npz array_equal、memcmp）两层。
