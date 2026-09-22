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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
本机实测（Apple clang version 17.0.0 / clang-1700.4.4.1），自包含、可当场重跑：

cd "$(mktemp -d)" && mkdir -p correct first
printf '#ifndef BASE_H\n#define BASE_H\ntypedef float Real_t;\n#endif\n' > base.hpp
printf '#ifndef INNER_H\n#define INNER_H\n#include "base.hpp"\nnamespace amw {\nint inner_fn();\n}\n#endif\n' > inner.hpp
printf '#ifndef OUTER_H\n#define OUTER_H\n#include "base.hpp"\n#include "inner.hpp"\nnamespace amw {\n}\n#endif\n' > correct/outer.hpp
printf '#ifndef OUTER_H\n#define OUTER_H\n#include "base.hpp"\nnamespace amw {\n#include "inner.hpp"\n}\n#endif\n' > first/outer.hpp
printf '#include "correct/outer.hpp"\nint main(){ return amw::inner_fn(); }\n' > tu_correct.cpp
printf '#include "first/outer.hpp"\nint main(){ return amw::inner_fn(); }\n' > tu_first.cpp
clang++ -std=c++17 -I. -fsyntax-only tu_correct.cpp; echo "correct rc=$?"
clang++ -std=c++17 -I. -fsyntax-only tu_first.cpp; echo "first rc=$?"

实测输出：
- correct 变体（namespace 开在最后一条 include 之后）：correct rc=0（无输出）。
- first 变体（namespace 开在第一条 include 之后，后续 include 落进命名空间、被包头的同名 namespace 再开一层）：
  tu_first.cpp:2:20: error: no member named 'inner_fn' in namespace 'amw'; did you mean 'amw::amw::inner_fn'?
  ./inner.hpp:5:5: note: 'amw::amw::inner_fn' declared here
  first rc=1
即复现了主张里的「同名 namespace 逐层嵌套」与「did you mean '...::amw::amw::...'」信号。另可加一条：把 base.hpp 的 #include 放进 namespace 内，全局作用域引用 Real_t 即得 "unknown type name 'Real_t'; did you mean 'amw::Real_t'?"（本机同样复现），对应条目里的 unknown type name 形态。
```

**审核给出的修改意见（要点）**：留注入集，只换证据、不动主张：证据节的 4 条全部落在两处已消失的 /tmp 沙箱（/tmp/review-refute-ns、/tmp/review-scan-core）且命令在切片中被截断，无法照抄复跑——建议把证据 4（或新增一条）替换为 minimalRepro 里那段自包含 clang 复现，使该条可被任何未来会话当场重跑。主张真值（C++ 命名空间作用域/嵌套 + #include 纯文本展开 + #ifndef 守卫）是语言/clang 的稳定属性，本次已独立复现，故保留在 playbook、并保留 verified_by: command。措辞微调：为什么节首条的「namespace 开在 include 之前」与实测情形不精确对齐，应改为「namespace 开在第一条 include 之后（等价于后续 include 都落在命名空间内）」；同条把 unknown type name 的成因从「守卫单独致因」收窄为「基础头的 #include 落进命名空间使其类型被限定 + 守卫阻止其在该 TU 内于全局作用域重新展开」，二者共同作用。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
