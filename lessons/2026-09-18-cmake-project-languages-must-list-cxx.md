---
id: cmake-project-languages-must-list-cxx
type: lesson
status: candidate
scope: global
domain: build-system
tags: [cmake, cxx, project-languages, configure-failure, c-to-cpp17]
triggers:
  - "把 C 工程（.c 源码）切到 C++17 编译，顶层 CMakeLists 的 project() 只声明了 C"
  - "cmake 配置阶段非零退出，日志里只识别到 C 编译器，而 build.log 根本没被创建（失败信号）"
  - "用 set_source_files_properties(... LANGUAGE CXX) 或 CMAKE_CXX_STANDARD 让 .c 走 C++ 编译器"
  - "cmake --build 根本没执行到：A && B 链在配置失败处断开导致没有编译日志（失败信号）"
  - "给已有 CMake C 工程打开 C++ 语言，不确定要不要动 project() 或 enable_language()"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af35-8863-7097-91f3-80ea6b63439a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [cmake-default-build-type-no-optimization, fma-contraction-invalidates-bitwise-acceptance-gates]
---

## 主张

把一个纯 C 工程切成 C++17 编译时，**只改源码语言（`LANGUAGE CXX` / `-std=c++17`）而不在顶层 `project()` 的语言列表里加 `CXX`，CMake 会直接死在配置阶段**——不是编不过，而是 `cmake -S . -B build` 本身返回非零，`cmake --build` 从未执行，连构建日志文件都不会生成。修法：`project(<name> C CXX)`（或等价的 `enable_language(CXX)`）。

## 为什么

`project(x C)` 只启用 C 语言工具链；此后任何要求 C++ 编译的源文件属性/目标在 configure/generate 阶段就找不到 `CMAKE_CXX_*` 变量，于是失败被提前到配置期。**这一点让误判方向反了**：看到「构建失败」会去翻 build.log，而 build.log 不存在，人会转而怀疑 rsync/路径/磁盘，实际根因在 `project()` 那一行。

## 证据（切片命令 ↔ 结果）

- 只打补丁（把 core 源码切成 C++）后跑构建：
  `$ cmake -S . -B build -DCMAKE_BUILD_TYPE=Release > cfg.log 2>&1 && cmake --build build -j8 > build.log 2>&1; echo "build rc=$?"`
  → `build rc=1`，且 `grep: /tmp/amw17/build.log: No such file or directory` ×2：**rc=1 来自配置，`&&` 短路使 `cmake --build` 从未运行**。
- `tail -25 cfg.log` → 日志尾部只有 `The C compiler identification is AppleClang 17.0.0.17000404` / `Detecting C compiler ABI info`：**只有 C 工具链被识别，没有 CXX 检测行**。
- 改 `project()` 语言后重跑：`sed -i '' 's/^project(algommw C)$/project(algommw C CXX)/' CMakeLists.txt` → 文件头变为 `project(algommw C CXX)`，同一构建命令得 `build rc=0` + `(error count: 0)` + ctest 全过。

对照：同一会话里逐 TU 试编探针（不走 CMake）报 `TUs: 25 === SUMMARY: OK=25 FAIL=0`，说明源码本身没有 C++ 兼容性问题——**失败的唯一变量是 CMake 语言列表**。

## 反例 / 边界

- 只适用于「C 源码在 CMake 里被要求按 C++ 编」；子项目自己 `project()`/`enable_language(CXX)` 也可能救回来，此时症状变成只有部分目标失败，不再适用本条判据。
- `build.log` 不存在是本条的强指纹，但它同样出现在「上一轮构建日志被清理」的场景；要同时看 `cfg.log` 尾部有没有 CXX 检测行，二者一起才算定位。
- 本条不涉及语言切换后的真实编译/数值风险，那部分见 `fma-contraction-invalidates-bitwise-acceptance-gates` 与 C→C++17 相关的 libm 符号条目。

## 失败信号（未来命中即该想起本条）

- `cmake --build` 的日志文件根本没生成，而 `${build}/CMakeFiles/` 下也没东西。
- 配置日志的最后一屏停在 `The C compiler identification ... Detecting C compiler ...`。
- 源码逐 TU 手编 `clang++ -x c++ -std=c++17 -c` 全绿，但 CMake 构建一上来就失败。
