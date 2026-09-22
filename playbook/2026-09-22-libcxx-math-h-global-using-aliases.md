---
id: libcxx-math-h-global-using-aliases
type: fact
status: validated
scope: global
domain: cpp-toolchain
tags: [macos, libc++, math.h, __math, overload, ambiguity]
triggers:
  - "macOS 上 C++ 未限定 sin/fabs 调用与自定义同名重载二义，要找另一候选来自哪个头"
  - "审计 libm 遮蔽 shim 的二义源，只查了 /usr/include/math.h，没查 SDK 的 c++/v1/math.h（失败信号）"
  - "要在 Apple SDK 里确认 libm 重载被哪些 using 声明引入、float 版实现在哪"
  - "把 macOS 上复现的 C++ 数学重载二义换平台复现时，要解释全局候选集的构成"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-5f94-7475-af70-36af963834d5
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [using-directive-vs-shim-namespace-ambiguity, libm-shim-include-demote-from-common-header]
---

# macOS 的 libc++ `<math.h>` 用 `using std::__math::…` 把整套 libm 重载（含 float 版）带进未限定可见的重载集

**主张**：macOS Apple SDK 的 `c++/v1/math.h` 在引入 C 的 `math.h` 之后，用整批 `using std::__math::…` 声明把数学函数重载（`cos/fabs/sin/lround/…`，含 float 实参版本）引入未限定可见的作用域；C 的 math.h 则声明 `extern double sin(double)`（行 353）与 `extern double fabs(double)`（行 441）。float 版实现在 `__math/trigonometric_functions.h:42`（`float sin(float)`）。因此 macOS 上未限定的 `sin/fabs` 本来就不是单体函数：任何再加进同名候选的改动（自定义 shim、`using namespace` 引入核心命名空间）都可能立刻二义。

**为什么（怎么用）**：审计 `call to 'X' is ambiguous` 时，列出所有候选来源才能定位。macOS 上的候选集至少两路：C math.h 的 double 声明 + libc++ math.h 的 `std::__math` 别名。项目自己的 shim/using-directive 是第三路。只知道「我的头里定义了同名函数」不足以解释二义，也不足以判断换平台后是否复现。

**证据（本会话切片，命令 ↔ 结果）**：

- `V1=$SDK/usr/include/c++/v1; rg -n 'using std::__math::(fabs|…' $V1/math.h` → `457:using std::__math::cos; 464:using std::__math::fabs; 484:using std::__math::lround; 497:using std::__math::sin; 499:…`（切片截断）。
- `rg -n '^extern double (sin|fabs)\(double\);' "$SDK/usr/include/math.h"` → `353:extern double sin(double); 441:extern double fabs(double);`（同一命令复跑还带出 464/497 的 using 行）。
- `rg -n 'sin\(' $V1/__math/trigono…`（切片路径截断）→ `42:inline _LIBCPP_HIDE_FROM_ABI float sin(float __x) _NOEXCEPT { return __builtin_sinf(__x); }`。
- 对应的二义复现与最小形状：`min_double.cpp:4:31: error: call to 'sin' is ambiguous`；`v0/tests/unit/test_eig.cpp:94:25: error: call to 'fabs' is ambiguous`。
- 本会话的逐 TU 归类把冲突来源记为 `math.h(double-overload)`（`v0/tests/integration/test_doa_beam.cpp  math.h(double-overload) notes=5`）。

**边界 / 反例**：

- 行号/内容是本机 Xcode SDK 快照（`xcrun --show-sdk-path` 得到的那份），换 SDK 版本会变；「libc++ 为 `math.h` 补重载模板 + using 声明」是 libc++ 的实现方式，GCC/libstdc++ 与 MSVC 不同，不能照搬。
- 这些 using 行具体处在全局还是 `std` 里，按 SDK 文件本身判读：本会话在 SDK 文件内 grep 到它们；本轮 reflector 复核原文件，位于 `_LIBCPP_END_NAMESPACE_STD` 之后、`extern "C++"` 块内（该复核不在会话切片内）。
- 「候选集有多个」不等于「必然二义」：只有两个候选对同一调用难分优劣时才报错；本条只提供候选来源清单，不替代逐调用点的重载解析判断。

**失败信号（未来命中即该想起本条）**：在 macOS 上排查未限定数学调用二义时只 grep 了 `/usr/include/math.h`，没查 `c++/v1/math.h` 的 `using std::__math::` 行；或把二义全归因给自己写的 shim 而说不清另一候选。

> **同源（n 记账）**：本条与同一会话 `01a0b74a-5f94` 的另 3 条提案同源于D10/libm 遮蔽那一组变体实验——**一次观测被拆成多条**，别当独立经验计权。
> 更大一层：2026-09-18 那批有 3 个会话在 **33 秒内**先后启动、切片里「首条 user」逐字相同（对同一份 PLAN.md 的并行符合性审计），所以 A/B 两簇 12 条的**有效独立来源 ≈2 次**，不是 12 次。
> 另：`evo slice` 会**截断长命令**——凡依赖被截断部分的引用，只能算「当时跑过」。
