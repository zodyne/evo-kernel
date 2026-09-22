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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
Self-contained two-target CMake repro (run in an empty dir; no network, no Algommw repo needed):
R=$(mktemp -d); mkdir -p "$R/core" "$R/tools/parity"
printf 'cmake_minimum_required(VERSION 3.20)\nproject(mre CXX)\nadd_library(core core/main.cpp)\nadd_executable(parity tools/parity/main.cpp)\ntarget_link_libraries(parity PRIVATE core)\n' > "$R/CMakeLists.txt"
printf '#pragma once\ninline int ok(){return 1;}\n' > "$R/core/ok.hpp"
printf '#include "ok.hpp"\nint core_entry(){return ok();}\n' > "$R/core/main.cpp"
printf '#pragma once\nnamespace amw;   // bulk-edit damage (was: using namespace amw;)\ninline int bad(){return 0;}\n' > "$R/tools/parity/broken.hpp"
printf '#include "broken.hpp"\nint main(){return bad();}\n' > "$R/tools/parity/main.cpp"
cd "$R" && cmake -S . -B build >/dev/null 2>&1
cmake --build build --target core -j1 >core.log 2>&1; echo "core  rc=$? errors=$(grep -c 'error:' core.log)"
cmake --build build --target parity -j1 >parity.log 2>&1; echo "parity rc=$? errors=$(grep -c 'error:' parity.log)"
Ran 2026-09-22 on cmake 4.4.2 / clang++ (darwin). Expected + observed output:
  core   rc=0 errors=0
  parity rc=2 errors=1
  .../tools/parity/broken.hpp:2:14: error: expected '{'
i.e. building target `core` returns rc=0 while a broken header compiled only by target `parity` is caught only when that target (or the whole tree) is built.
```

**审核给出的修改意见（要点）**：主张本身站得住（我已在 2026-09-22 用自包含双目标 CMake 工程独立复现：core rc=0 / parity rc=2 于 core 闭包外的头文件报错），故留在注入集。但证据节必须换证据：三条命令都取自复核 agent 的 /tmp/review-scan-tests 诊断副本（非真仓、且被 apply_card.py 改写过的当时状态），切片中命令尾部被截断，照抄无法重跑。改法：(1) 用 minimalRepro 里那段自包含工程替换「证据」节三条命令——它不依赖任何外部仓/沙箱，直接演示「单目标 rc=0 掩盖另一目标闭包内文件的错误」；(2) 把「为什么」节保留（CMake target 依赖闭包不同这一机制正确且可复现），但删去对 algommw-plus 具体路径/文件的指涉，使其与证据一致；(3) 主张文字可原样保留，一般律成立。verified_by: command 维持。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
