---
id: asan-ubsan-out-of-tree-ctest-audit
type: lesson
status: candidate
scope: global
domain: c-testing
tags: [c, sanitizer, asan, ubsan, cmake, ctest, audit]
triggers:
  - "只读审查 C/C++ 库，要在不动被测仓库的前提下给出内存安全/UB 结论"
  - "接手 C 项目审查，不知道除通读代码外还能拿什么硬证据"
  - "想跑 AddressSanitizer + UBSan 又怕污染仓库里的 build/ 目录"
  - "sanitizer 构建跑测试满屏 leak 报告，真实越界/UB 被淹没（需 ASAN_OPTIONS=detect_leaks=0）"
  - "ctest/pytest 全绿就想在结论里写『无内存安全问题』（失败信号：只跑了默认构建）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5b31-7353-8a3d-42c878dd751c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [mutation-testing-verifies-tests-catch-bugs, c-test-undef-ndebug-before-assert-include]
---

# 主张

审查一个 C 算法库的内存/UB 安全时，用**仓库外的独立构建目录**（如 `/tmp/<proj>-asan`）配出 ASan(+UBSan) 构建、跑**全量** ctest，是一条低成本、可复现的硬证据路径；运行测试时用 `ASAN_OPTIONS=detect_leaks=0` 去掉泄漏噪声、`UBSAN_OPTIONS=print_stacktrace=1` 拿调用栈。既不动被测仓库的 `build/`（只读审查约束），又把「现有测试路径无越界、无 UB」变成一条可引用的实测结论。

# 做法（本会话实测的三步）

1. 独立配置（源码目录只读传入，构建产物落 /tmp）：
   `cmake -S /Users/zodyne/Dev/algommw -B /tmp/algommw-asan -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_FLAGS="-fsanitize=address…"`
   （切片里 `-DCMAKE_C_FLAGS` 被截断，仅 `-fsanitize=address` 直接可见；UBSan 由第 3 步的 `UBSAN_OPTIONS=print_stacktrace=1` 与末尾结论「ASan+UBSan 独立构建」共同佐证。）
2. 构建：`cmake --build /tmp/algommw-asan -j4 > /tmp/build_asan.log 2>&1` ↳ `exit=0`。
3. 全量测试：`cd /tmp/algommw-asan && ASAN_OPTIONS=detect_leaks=0 UBSAN_OPTIONS=print_stacktrace=1 ctest --output-on-failure` ↳ `exit=0`，输出 `1/24 Test #1: unit_range .... Passed 1.20 sec`、`2/24 Test #2: unit_doppler_fft ...`（24 个用例全过）。

# 边界 / 反例

- 「24 个用例在 sanitizer 下全绿」只覆盖**已测路径**：本会话随后针对测试未覆盖的组合写的 /tmp 探针，仍发现 N=1 窗系数为 `nan`（`hann N=1 coef=nan isnan=1 …`）。这条结论不能写成「无内存安全缺陷」。
- `detect_leaks=0` 只是去噪，不等于被测代码无泄漏；要查泄漏应另跑一次带 `detect_leaks=1` 的构建。
- 切片仅直接可见 `-fsanitize=address`；若要在配方里固定 UBSan 开关写法，应现场从被测项目的构建脚本确认，不要照抄本条命令行。
