---
id: mutation-testing-verifies-tests-catch-bugs
type: lesson
status: validated
scope: global
domain: testing
tags: [mutation-testing, c, unit-test, test-quality, abort]
triggers:
  - "测试全绿但怀疑测试没真在抓 bug"
  - "想知道单测是否真能捕获缺陷"
  - "给 C/C++ 单元测试补缺口"
  - "改坏源文件守卫后测试应 abort（失败信号：不 abort）"
  - "测试套件有效性验证"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a56f-582e-7353-8a3d-42c5ca5a3860
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [c-test-undef-ndebug-before-assert-include]
---

# 变异测试验证测试有效性：改坏守卫后测试应 abort

## 主张

测试全绿 ≠ 测试真在抓 bug。用**变异测试**验证：把源文件的守卫删掉/改坏后跑单测，若测试不 abort 就说明测试有缺口，据此补用例。审查中改坏 `chain.c` 的 DDM×music/dml 守卫后跑单测得到 `Abort trap: 6`（4 个突变全被 abort 捕获），证明测试确实在抓 bug，进而补齐 `test_doa_scan.c` 用例组 I 与 `test_dpu_validate.c` 边界两条。

## 证据

- `-- [DDM x music/dml] mutated core/src/chain/chain.c` → `/bin/bash: line 37: 1477 Abort trap: 6 ./build/tests/unit...`（变异后测试如期 abort）。
- 4 个突变全被 abort 捕获（删守卫 → exit 134），据此定位 M2 测试缺口并补用例组。

## 边界

- 适用于 C/C++ 单测（assert/abort 语义明确）；解释型语言需等价断言失败机制。
- 与「NDEBUG 剥离 assert 导致静默通过」不同坑：那条是构建参数问题（见 related），这条是「测试存在但没覆盖该分支」。
