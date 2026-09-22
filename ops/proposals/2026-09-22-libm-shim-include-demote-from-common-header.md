---
id: libm-shim-include-demote-from-common-header
type: lesson
status: candidate
scope: global
domain: cpp
tags: [cpp, libm, shim, include-closure, ambiguity, header]
triggers:
  - "把 libm 遮蔽/包装头 include 进被所有 core 头共用的公共头（如 base/fp.hpp），消费者 TU 报 call to 'X' is ambiguous"
  - "复核报告声称『不改消费者测试体就无法编译』，要评估是否存在零测试改动的解（失败信号：直接接受不可能性结论）"
  - "想缩小 libm 遮蔽 shim 的二义爆炸半径，考虑把 shim 的 include 从公共头下移到 core 的 .cpp"
  - "core 头文件闭包里搜不到 libm 调用、只有个别 .cpp 用 shim，犹豫 shim 头该放哪一层"
  - "验证 shim 头不再进消费者路径后，float 实参是否仍会被 delete 守卫拦住"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-5f94-7475-af70-36af963834d5
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [using-directive-vs-shim-namespace-ambiguity, include-closure-per-tu-impact-count, libm-symbol-chosen-by-arg-type-not-call-syntax]
---

# 把 libm 遮蔽头的 include 从公共头下移到 core 的 .cpp，可零测试改动消除消费者 TU 的二义

**主张**：当 libm 遮蔽头（D10 类 `base/libm.hpp`）被一个所有 core 头都包含的公共头（`base/fp.hpp`）拉进消费者 TU 时，测试里未限定的 `sin/fabs` 调用会与遮蔽重载二义（本仓基准变体 v0：`test_doa_beam.cpp ambiguous=5 all_errors=5`、`test_eig.cpp:94:25: error: call to 'fabs' is ambiguous`）。把 `base/libm.hpp` 从 `base/fp.hpp` 移出、改由 core 的 `.cpp` 直接包含（变体 E1），测试侧二义消失（`./compile_all.sh ve` 汇总标注 tests all-clear，末行 `ambiguous=0 all_errors=0`），且不需要改任何测试体。所以「消费者测试 TU 必须改测试体才能编译」不是必然结论。

**为什么**：二义只发生在「遮蔽重载对未限定调用可见」的 TU。shim 头经公共头进入每个消费者 TU 的 include 闭包，就把 `amw::sin/fabs` 放进了它们的候选集；消费者测试恰恰用未限定名调用 libm。把 shim 的 include 下移到 core 的 `.cpp` 后，消费者 TU 的闭包里不再有遮蔽声明，未限定调用只剩标准库候选；而真正需要遮蔽语义的 core 实现 TU 仍直接包含 shim，`delete` 守卫照常生效。

**证据（本会话切片，命令 ↔ 结果）**：

- 二义复现（基准 v0，24 个测试文件被改写）：`tests/integration/test_doa_beam.cpp ambiguous=5 all_errors=5`；单 TU 原文 `v0/tests/unit/test_eig.cpp:94:25: error: call to 'fabs' is ambiguous`；最小 D10 形状探针 `min_double.cpp:4:31: error: call to 'sin' is ambiguous`。
- 注入路径确认：core 头里搜 libm 调用，可见结果只有 shim 自身（`=== libm calls inside core HEADERS (should be none if option i viable) === repo/core/include/base/libm.hpp:8:inline doub…`）；实际调用方是 core 的 `.cpp`（`core/src/math/eig.cpp:70: Real_t mag = ( Real_t ) sqrt( … )`）。
- 变体 E1 构造：`##### Variant E (fp.hpp does NOT include libm.hpp; .cpp includes it) #####`，随后 `=== E1: tests all-clear summary === tests/unit/test_tracking_module.cpp ambiguous=0 all_errors=0`（切片只保留 `./compile_all.sh ve 2>&1 | tail -3` 的末行）。
- 守卫仍生效：`=== guard_probe with ve/core/include (fp.hpp w/o libm, libm.hpp direct) === guard_probe.cpp:6:38: error: call to deleted function 'sqrt'`——直接包含 shim 的探针里，float 实参仍被 `delete` 守卫拦住。
- 末条 assistant 结论原文：E1 为推荐解（「libm.hpp 改由 core `.cpp` 包含」）。

**边界 / 反例**：

- 下移的前提是公共头链上确实没有需要遮蔽语义的 libm 调用；若某个公共头/内联函数自身要调用被遮蔽的 libm，下移后该处会失去遮蔽（或被删重载拦住），需要单独处置。本仓切片里 core 头的可见扫描命中只有 shim 自身。
- 验证面是消费者 TU 的逐 TU 语法编译（切片只保留汇总末行，未给全量 24 TU 清单）；core 目标的完整构建与链接未在切片中展示。
- 数字（ambiguous=5、行号）与目录布局是当次仓库 + 遮蔽实现的快照，换版本要重测。

**失败信号（未来命中即该想起本条）**：报告把「消费者 TU 二义」归因成必须改测试/消费者代码；或 shim 头的 include 出现在被大量头包含的公共头里，而全库头文件的闭包里其实没人调用它。
