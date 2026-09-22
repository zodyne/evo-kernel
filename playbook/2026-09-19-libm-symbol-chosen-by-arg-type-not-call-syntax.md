---
id: libm-symbol-chosen-by-arg-type-not-call-syntax
type: lesson
status: validated
scope: global
domain: tooling
tags: [cpp17, libm, overload-resolution, nm, symbol-table]
triggers:
  - "审计某个 TU 到底引用哪个 libm 符号（_sinf 还是 _sin），判断切 C++17 后数学实现有没有变"
  - "发现方声称 `(std::sin)(x)` / `(::sin)(x)` 这类写法绕过了按 `std::sin(` 写的正则，据此说闸门漏掉 float 调用"
  - "nm -u 里出现 _sinf，怀疑是加括号 / 限定符 / 命名空间写法改变了重载解析"
  - "要证明 float 实参在 C++ 下调用的是 float 版 libm 而不是静默升到 double 版"
  - "同一段数学调用在 C 与 C++ 下符号表对不上，想先排除写法（括号 / 限定）造成的假差异（失败信号）"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-cd18-7475-af70-36cd8df466ea
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [cpp-mode-libm-symbol-diff-per-tu]
---

## 主张

`nm -u` 上的 libm 符号由**实参类型**决定：float 实参 → `_sinf`，double 实参 → `_sin`；调用点的写法不改变这个结果——`std::sin` 与 `::sin`、加不加限定、把函数名括起来写成 `(std::sin)(x)`，都解析到同一个重载、落到同一个符号。

## 为什么（怎么用）

复核「源码正则只认 `std::sin(`，所以漏掉了 float 调用」这类发现时，要把两件事分开：正则的覆盖面是**审计口径**问题；而产物里到底引用哪个符号，由 C++ 重载解析按实参类型定。本会话用隔离 TU 实测：被声称绕过的括号写法 `(std::sin)(float)` 仍然落到 `_sinf`——写法差异并没有换来「静默升到 double 版」这种数值后果。

## 证据（切片命令 ↔ 结果）

1. 写入括号包裹的限定调用探针：`cat > t_stdparen.cpp`，正文含 `float g_stdparen(float x){ return (std::sin)(x)`。
2. 逐 TU 隔离编译后取 `nm -u`（`mk(){ printf '%s\n' "$2" > "iso_$1.cpp"; clang++ -std=c++17 -O3 -fno-…`）：
   `stdparen_float -> _sinf  stdparen_double -> _sin  globparen_float -> _sinf`（切片在此截断；对应用例名为 `_float` / `_double`）。
3. 注入场景同样复现：`injected_float` TU → `compile: OK  C-seg regex hits: 0  nm -u: _sinf`；
   函数指针形态 `injected_fptr.cpp`（正文 `double probe( float x`）→ `compile OK  C-seg hits: 0  nm -u: _sin`（走的是 double 版，故按浮点符号判的 B 段零命中）。

## 边界 / 反例

- 实测环境是 `clang++ -std=c++17 -O3`；符号前导下划线数量随平台/ABI 变，但「按实参类型选重载」是语言规则。
- 本会话只覆盖 float/double 实参 × 限定/括号写法；整型实参、`using` 注入、模板糖、显式 `std::sin<float>` 等形态未测。
- 与 `cpp-mode-libm-symbol-diff-per-tu` 互补：那条讲「切到 C++17 后要逐 TU 比 libm 符号表」，本条给出「符号由什么决定」的判据，用于在比对出差时先排除写法造成的假差异。
