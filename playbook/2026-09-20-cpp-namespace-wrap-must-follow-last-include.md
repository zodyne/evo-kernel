---
id: cpp-namespace-wrap-must-follow-last-include
type: lesson
status: validated
scope: global
domain: c-porting
tags: [cpp, namespace, include-order, libm-shadowing, build-errors]
triggers:
  - "给 C++ 头文件套 namespace { } 做同名符号遮蔽（libm 遮蔽 / 符号隔离），要决定它插在 include 区的哪个位置"
  - "编译报 ns::ns::ns::<类型> 这类三级嵌套限定，或 did you mean '::a::a::a::X'（失败信号）"
  - "报 unknown type name 'Real_t' 等基础头里定义的类型，且错误量级上百（失败信号）"
  - "批量给一组互相 include 的头文件加 namespace 后，core 目标从可链接变成级联编译失败"
  - "A/B 对比两个构建日志判断 namespace 位置对错——错误 27 条对 150 条、一边 Built target core 一边没有"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-ed35-7475-af70-36c019db3bf9
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [cpp-mode-libm-symbol-diff-per-tu]
---

# 主张

给一批互相 `#include` 的头文件套 `namespace <ns> { ... }`（libm 同名遮蔽 / 符号隔离）时，`namespace` 必须开在**最后一条 `#include` 之后**。开在第一条 include 之后，后续 include 的内容会落进命名空间，且被包裹的头再被 include 时同名 namespace 逐层嵌套：实测错误量从 27–28 条涨到 150 条，`amw::amw::` 出现 206 处、出现三级限定 `did you mean '::amw::amw::amw::ComplexF_t'`、`unknown type name 'Real_t'` 47 处 / `ComplexF_t` 18 处 / `dPi` 2 处；而开在最后一条 include 之后的一侧，`core` 目标链接出了 `libcore.a`（`[ 32%] Built target core`）。

# 为什么 / 判据

- `#include` 是纯文本展开：namespace 开在 include 之前，被包含头里的声明就成了 `<ns>::X`；这些头自身的 `#ifndef` 守卫在该 TU 只放行一次，后续在 namespace 外（或别的嵌套层）引用这些名字即找不到——`Real_t` / `ComplexF_t` 这类基础类型报 unknown 就是这个形态。
- 头文件互相 include 时，内层再写一次 `namespace <ns>` 得到的是 `<ns>::<ns>`（内层同名 namespace 是嵌套，不是重开），层级随 include 链累加，于是错误提示里出现三级限定。
- 判据取「产物」而不是「状态字」：配置阶段两边都是 `cfg rc=0`，只有 build 阶段的错误计数与 `Built target core` 能区分两种位置。

# 边界 / 反例

- 放在最后一条 include 之后**只保证 core 目标能构建**：实测该侧仍是 `build rc=2`，27–28 条错误里 26 条集中在 `tests/`（`tests/unit/test_tracking_module.cpp:55:23: error: call to 's...'`）。别把「core 构建成功」当整仓验收通过；也别因测试仍红就否掉这个位置。
- 计数口径会差 1：同一份日志 `grep -c 'error:'` 得 27（数行），`grep -o "error:" | wc -l` 得 28（数出现次数）。引用数字要带口径。
- 本切片只覆盖 Apple SDK / clang 下的这一组头文件与 core 目标；模板、宏生成的 include、条件编译里的 include 位置未测。

# 证据（切片命令 ↔ 结果）

1. 两份 rsync 副本来自同一源仓库（`--exclude .git --exclude build`），唯一变量是 namespace 位置：
   `python3 apply.py repo_correct last repair1` / `python3 apply.py repo_first first repair1`
   → `applied mode=last repair=True` / `applied mode=first repair=True`；
   `head -6 repo_first/core/include/types/waveform.hpp` → `#ifndef TYPES_WAVEFORM_H` / `#define TYPES_WAVEFORM_H` / `#include "base/fp.hpp"` / `namespace ...`（namespace 紧跟第一条 include）。
2. 两侧配置都过：`cmake -S . -B build -DCMAKE_BUILD_TYPE=Release` → 各 `cfg rc=0`（配置成功不区分位置）。
3. 构建对比（`cmake --build build -j8 > build.log 2>&1`）：
   - namespace 在**最后**一条 include 之后（repo_correct）：`build rc=2`，`errors: 27`；`grep -E "Built target core|Linking CXX static library libcore.a"` → `[ 32%] Linking CXX static library libcore.a` 与 `[ 32%] Built target core`；错误分布 28 / 26 条落在 `tests/`。
   - namespace 在**第一**条 include 之后（repo_first）：`build rc=2`，`errors: 150`；错误种类统计 `Real_t: 47  ComplexF_t: 18  dPi: 2  amw::amw:: 206`；`grep -o "did you mean '::amw::amw::amw::ComplexF_t'"` 有命中（三级嵌套）。
4. 独立副本复核：`/tmp/review-scan-core/build7.log` → `total error lines: 147`，`Real_t: 46  ComplexF_t: 18  amw::amw:: 202`（同一失败指纹，量级一致）。
