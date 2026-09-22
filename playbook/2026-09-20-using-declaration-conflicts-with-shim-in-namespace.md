---
id: using-declaration-conflicts-with-shim-in-namespace
type: lesson
status: validated
scope: global
domain: cpp
tags: [cpp, using-declaration, name-lookup, libm, shim, compile-error]
triggers:
  - "在已有同名函数声明的 namespace 里写 `using std::sin;`，想引入 std 重载"
  - "编译报 `target of using declaration conflicts with declaration` 类错误（失败信号）"
  - "libm 遮蔽 shim（D10 类头）已把 sin/cos 声明进本命名空间，探针/实现要调用 std 版"
  - "同一段探针去掉 shim 头就编过、加上 shim 头就挂（失败信号）"
  - "要在不改 shim 的前提下从被遮蔽命名空间内部调用 `std::sin`，纠结写 using 还是显式限定"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-e147-7475-af70-36ce8acff051
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [libm-symbol-chosen-by-arg-type-not-call-syntax, cpp-namespace-wrap-must-follow-last-include]
---

# 同作用域已有同名 shim 声明时，`using std::sin;` 编不过

## 主张

命名空间里**已经有**与 `std` 同名的函数声明时（典型：D10 类 libm 遮蔽 shim 在 `namespace amw` 里声明了 `sin/cos/…`），再写 `using std::sin;` 会把冲突名字引入同一作用域，clang 直接报 `error: target of using declaration conflicts with declaration`。要在被遮蔽的命名空间内部调用 std 版，只能用**显式限定** `std::sin(x)`，不能靠 using 声明「引回来」。

## 为什么

`using std::sin;` 是把 `::std::sin` 这个名字引入当前作用域；若当前作用域已有一个冲突的同名声明，C++ 判定为冲突（不是把两个重载合并）。因此「先包含 shim，再 using」必然编译失败；同一段代码在没有该声明的 TU 里完好。

## 证据（切片命令 ↔ 结果）

同一批探针、同一编译模式（`clang++ -std=c++17 -O3`），唯一差别是有没有先吃进 shim 头：

- `u1_noname`（无 shim 声明，正文 `#include <cmath>` + `namespace amw { using std::sin; void f( dou…`）→ `rc=0`（编过）。
- `u2_after_libm`（先包含 D10 `libm.hpp` shim，再写 `using std::sin;`）→
  `u2_after_libm.cpp:2:28: error: target of using declaration conflicts with d…`

两探针在同一命令里成对编译，排除了编译选项/环境差异。

## 边界 / 反例

- 冲突由「同作用域已有同名声明」触发，不是 `using` 语法本身的问题；换一个没有该声明的命名空间（`u1_noname`）就编得过。
- 诊断文案是 clang 的；别的编译器措辞可能不同，但「using 声明与同作用域声明冲突」这条名字查找判定不变。是否冲突还取决于 shim 声明的具体签名/实体，换个 shim 写法要重测。
- 本条不主张「shim 存在时不能调 std 版」：显式限定 `std::sin(...)` 正是绕开遮蔽的写法——也正因如此，源码正则闸门才要专封限定调用（见 related）。
