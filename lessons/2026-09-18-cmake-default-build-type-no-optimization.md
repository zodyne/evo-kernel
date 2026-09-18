---
id: cmake-default-build-type-no-optimization
type: lesson
status: candidate
scope: global
domain: c-build
tags: [cmake, build-type, optimization, o0, silent-perf]
triggers:
  - "新建/迁移 CMake 工程，只跑 cmake -S . -B build 就以为拿到优化构建"
  - "构建命令里没有任何 -O 标志（等价 -O0），而仓库以为默认带优化（失败信号）"
  - "移植/重写 CMakeLists 后基准或吞吐比旧构建慢一截，却没有任何报错（失败信号）"
  - "希望仓库默认构建就带优化，不想每次手传 -DCMAKE_BUILD_TYPE=Release"
  - "对比新旧构建链的性能/浮点行为前，先要确认两边优化档位一致"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad30-a962-77c1-a593-51aa6abcdec8
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [fma-contraction-invalidates-bitwise-acceptance-gates, c-test-undef-ndebug-before-assert-include]
---

**主张**：CMake 在没有显式 `CMAKE_BUILD_TYPE`（或未在 CMakeLists 里兜底优化标志）时，`cmake -S . -B build` 生成的构建**不带任何 `-O` 标志，等价于 `-O0`**——性能工程不能依赖「默认就是优化构建」。修法是在顶层 `CMakeLists.txt` 写死默认优化（或显式要求调用者传 `-DCMAKE_BUILD_TYPE=Release`），让裸 `cmake -S . -B build` 也是优化构建。

**为什么**：`CMAKE_BUILD_TYPE` 缺省是空串，CMake 内置的 `CMAKE_C_FLAGS_<CONFIG>` 表就不会被选中，编译行里不会出现 `-O2/-O3`，也不报错。对纯数值/离线信号处理工程，这意味着验收时跑的是最慢、且浮点行为与发布档位不同的构建，性能与「和旧构建对拍」类结论都失真。

**证据**（本会话硬证据切片，命令 ↔ 结果）：
```
$ cd /Users/zodyne/Dev/algommw && echo "=== fast-math / march / fPIC ==="; grep -rniE "fast-math|ffp-contract|march|fPIC|O[0-3]|std=c" CMakeLists.txt ...
  ↳ CMakeLists.txt:12:# 默认带优化。**不加这段,`cmake -S . -B build` 会落进"无任何 -O 标志"的 -O0** —— CMakeLi…
```
即该项目在顶层 CMakeLists 里专门加了「默认带优化」的一段来兜底，并在注释中写明不加就会落进 `-O0`。注意证据是这份 CMakeLists 的自述（grep 取得），本会话**未**独立复跑 cmake 验证，故只把它当作构建配置事实使用。

**边界 / 反向信号**：
- 只影响「没显式指定构建类型」的调用路径；一旦调用者传了 `-DCMAKE_BUILD_TYPE=Release`，兜底段通常让位。
- 排查信号：`cmake -S . -B build && cmake --build build -v` 后编译行里搜不到 `-O`；或移植构建链后 golden/性能结论与旧构建对不上而代码没改。
- 与本条相邻但不同的坑：优化**开关语义**（`-ffp-contract`/fast-math）会改变逐位结果，见 `fma-contraction-invalidates-bitwise-acceptance-gates`；本条只讲**优化档位默认值**。
