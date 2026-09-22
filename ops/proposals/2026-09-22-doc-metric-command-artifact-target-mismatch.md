---
id: doc-metric-command-artifact-target-mismatch
type: lesson
status: candidate
scope: global
domain: documentation
tags: [doc-drift, build-target, cmake, artifact, conformance-audit]
triggers:
  - "复现 / 审计方案文档里的度量命令（nm / 构建 / 测试命令）"
  - "文档写的产物名（dylib/a/so）与 CMake add_library 实际目标对不上"
  - "照文档原样跑验证命令却找不到产物、或拿到与文档不符的数（失败信号）"
  - "CMake 里 core 是 STATIC，文档却按 dylib 写 nm -gU 命令"
  - "对拍脚本 legacy 侧 dlopen 旧仓 dylib，被误当作本仓核心产物"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b3e7-de9e-7475-af70-36a88ea79127
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [doc-selfreported-counts-drift, doc-drift-fix-grep-by-concept, verify-dylib-port-completeness-via-nm-symbols, verify-external-references]
---

# 文档里的度量命令会引用不存在的产物名：先按 CMake 核对实际 target，再在真实产物上复跑

**主张**：PLAN.md 的 M6（C ABI 完整度）度量命令写的是 `nm -gU libcore_cxx.dylib | grep -c ' T _'`，但本仓 core 的实际构建目标是静态库 `libcore.a`（`core/CMakeLists.txt:1` = `add_library(core STATIC)`，产物 `build/core/libcore.a`）；文档里的 dylib 名字在核到的 target 清单里不存在，只有 legacy 对拍侧会 `dlopen` 旧仓的 dylib。审计这类文档时，必须先在 CMakeLists 上核对产物名 / 库类型，再在真实产物上复跑度量命令。

**证据（本会话命令 ↔ 结果，只读）**：

- PLAN.md:57：``` `nm -gU libcore_cxx.dylib | grep -c ' T _'` vs `grep -c ' T __Z'` | 88 未修饰 / 4 已修饰（全部来自 `snap.h`）... ```
- `grep -n 'core_cxx\|dylib\|SHARED\|add_library' CMakeLists.txt core/CMakeLists.txt tools/parity/*.sh` → 根 CMakeLists.txt 零命中；`core/CMakeLists.txt:1:add_library(core STATIC)`；dylib 只出现在 `tools/parity/gate.sh:15` 的 `LEGACY=...`（旧仓产物路径）行。
- `cat core/CMakeLists.txt` → 首行即 `add_library(core STATIC)`。
- `tools/parity/CMakeLists.txt` 注释：`native 侧直接链接本仓 core;legacy 侧运行时 dlopen 旧仓 dylib`。
- 复跑 M6 用的是真实产物：`nm -gU build/core/libcore.a | grep -c ' T _'` → 88、` ' T __Z'` → 4，与 PLAN 的数字同口径对上——度量本身可在 `.a` 上复现，只是文档写的产物名不对。

**为什么**：文档里的复现 / 度量命令是一种会被别人原样执行的代码。产物名（dylib vs `.a`）和构建目标一旦不一致，命令要么直接找不到文件，要么（更隐蔽地）指向另一个产物给出看似合理的数字；库类型还会改变符号语义（动态库允许未定义符号、静态库按需归档）。

**边界 / 反例**：

- 本会话没有直接观察到 `nm -gU libcore_cxx.dylib` 的 file-not-found 输出（审计改用 `libcore.a`），「该文件不存在」是由 CMake target / 产物清单推断，不是实测到的报错。
- dylib 在仓库里并非完全不存在：对拍闸门 legacy 侧运行时 dlopen 旧仓 dylib。本条讲的是「文档把本仓 core 写成 dylib」这一处漂移，不是「仓库里没有 dylib」。
- 与 `verify-dylib-port-completeness-via-nm-symbols` 的区别：那条教怎么用 nm 查 dylib 符号是否齐全，本条教先确认文档指称的产物是否存在、类型对不对。

**失败信号**：照文档命令复跑时报找不到文件、或数字与文档对不上；或审计报告引用的产物名在任何 CMakeLists 里 grep 不到。
