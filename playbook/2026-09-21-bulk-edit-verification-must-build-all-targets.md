---
id: bulk-edit-verification-must-build-all-targets
type: lesson
status: validated
scope: global
domain: build
tags: [cmake, build, target, bulk-edit, verification, coverage]
triggers:
  - "批量树改写后只跑 cmake --build build --target <单个目标> 就准备收尾/写报告"
  - "单目标构建 rc=0，但改动过的头文件其实只被另一个 target 编译（失败信号）"
  - "改动横跨 core / tools/parity / tests 多个目标，要证明编译验证覆盖了改动面"
  - "机械改写后某文件直到单独 build 它所属的 target 才暴露编译错误"
  - "想用『core 编过了』代表整棵树编过了"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-60e8-7475-af70-36b8b52e029c
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [scripted-tree-transform-explodes-revert-first, diff-scope-subdir-filter-hides-sibling-changes, cpp-namespace-wrap-must-follow-last-include]
---

**主张**：机械改写横跨多个构建目标时，单个目标构建 `rc=0` 不能代表改动面已被编译验证——只被其它目标编译的文件（不在该目标的依赖闭包里）的错误会完全隐身。收尾必须把改动触及的每个目标都构建一遍（或直接全量 `cmake --build build`），再跑测试。

**为什么**：CMake target 的依赖闭包不同：`core` 不含 `tools/parity` 的源文件，`parity`/`tests` 的 TU 各自包含不同的头。批量脚本按目录/glob 改写时，改动面与任一单个 target 的源集不重合；用 core 的绿灯代表全绿，等于只验证了改动面的一个子集。

**证据（切片命令 ↔ 结果）**：

- 修完 core 侧错误后：`cmake --build build --target core -j1` ↳ `core rc=0 0`（0 errors）。
- 紧接着构建 parity：`cmake --build build --target parity -j1` ↳ `parity rc=2 1 4:…/tools/parity/decoder.hpp:16:17: error: expected namespace name`——该错误在 core 目标的全绿结果里完全不出现（decoder.hpp 不在 core 闭包内）。
- 全量构建与测试复验：`cmake -S repo -B build >/dev/null 2>&1; cmake --build build -j8` ↳ `all rc=0 0`；`ctest --test-dir build` ↳ 24 个测试（尾部显示 `Test #23: integration_pruning … Passed`）。

**边界 / 反例**：

- 「全量构建」是编译覆盖面的下限，不等于运行时/闸门覆盖：本会话 parity 的正确性还要靠 `tools/parity` 的逐字节比对与负对照（`negative_control.sh`）另证。
- 若某 target 因环境缺依赖本来就构建不了，要在报告里标注未覆盖，而不是用其它 target 的绿灯冒名顶替。
- 全量构建耗时大时，至少把「改动文件 → 哪些 target 编译它」枚举清楚再选择性构建；跳过哪个 target 必须有依据。

**失败信号（未来命中即该想起本条）**：报告写「构建通过（core rc=0）」，但 diff 里有 `tools/`/`tests/` 的文件；或同一批改动在某个非主目标上才第一次报编译错误。
