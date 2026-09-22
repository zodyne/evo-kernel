---
id: inline-constexpr-header-still-needs-include-guard
type: lesson
status: validated
scope: global
domain: cpp-headers
tags: [cpp17, header, include-guard, odr, inline, redefinition]
triggers:
  - "头文件里只定义 `inline constexpr` 变量或 `inline` 函数，犹豫要不要加 include guard（以为 inline 就不会重定义）"
  - "同一 TU 报 `error: redefinition of '<名字>'`，而该符号明明是 inline / inline constexpr（失败信号）"
  - "把各 TU 各写一份的 `#ifndef M_PI` 兜底改成共享头文件里的 `inline constexpr double dPi`"
  - "复核『某头文件缺 include guard』这类发现，要在同一 TU 里 include 两次做复现探针"
  - "新增头文件只有常量/内联函数定义，判断它是否仍需要 `#ifndef` 守卫"
created: 2026-09-19
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b755-1ced-7475-af70-36d31f08cee8
last_verified: 2026-09-19
superseded_by: null
schema_version: 1
related: [c-probe-local-header-include-resolves-source-dir, c11-static-assert-warns-under-cpp-pedantic]
---

# `inline constexpr` 变量 / `inline` 函数放进头文件，照样需要 include guard

## 主张

头文件里只定义 `inline constexpr` 变量或 `inline` 函数，**不能**免除 include guard：`inline` 只让**跨 TU** 的多份同定义合法，同一 TU 内把无守卫头文件包含两次，第二份仍是
`error: redefinition of '<名字>'`。补上 `#ifndef` / `#pragma once` 守卫后，同一探针即通过（rc=0）。

## 为什么

`inline`（变量/函数）放宽的是 ODR 里"多 TU 各一份定义"的约束，链接期合并成一份；但同一 TU 内出现两次同名定义是实打实的重复定义，编译器当场报错，跟 `inline` 无关。所以"内容只有常量/内联函数、链接器不会抱怨重复符号"≠"可以不加守卫"。新写的共享头文件（如把各 TU 的 `#ifndef M_PI` 兜底收拢成一份 `inline constexpr double dPi`）正是这条的典型受害者：只要某个 TU 直接或间接包含它两次就编不过。

## 证据（本会话切片，命令 ↔ 结果）

在 `/tmp/review-refute-fp-hpp-include-guard-missing` 里对 4 个无守卫头文件做「同一 TU include 两次」探针，全部复现：

- `fp_noguard.hpp`（`#pragma clang fp contract(off)` + `namespace amw { inline constexpr double dPi … }`）：
  `In file included from inc_twice.cpp:2: ./fp_noguard.hpp:4:41: error: redefinition of 'dPi'`（源行 `4 | namespace amw { inlin…`）。
- `libm_only.hpp`（`#include <cmath>` + `inline double sin( double d )`）：
  `./libm_only.hpp:4:15: error: redefinition of 'sin'` —— 内联函数同样中招。
- `fp_dpi_only.hpp`（pragma + `namespace amw { … dPi }`）：`./fp_dpi_only.hpp:4:41: error: redefinition of 'dPi'`。
- `fp_exact_card.hpp`（把卡的字面内容原样放进头文件）：
  `=== exact card content, twice === In file included from inc_exact_twice.cpp:2: ./fp_exact_card.hpp:4:41: error: redefini…`。

会话结论（末条 assistant）：技术事实成立并可复现（rc=1，**加 guard 后 rc=0**）。

## 边界 / 反例

- **只在不同 TU 各包含一次时不会报错**：那是 ODR 允许的用法，不是"可以省守卫"。
- 触发前提是"同一 TU 两次包含"（直接两次，或头 A 与头 B 都包含它）。探针只 include 一次编过**不能**证明守卫存在，也不能证明不会重定义。
- "机制在探针里可复现"≠"某条施工路径一定会踩到"：后者要在目标产物里指出重复包含路径，严重度另判（实例/触发路径证据见 `blind-spot-claim-needs-instance-count` 方向的条目）。
- `#pragma once` 与 `#ifndef` 宏守卫在本条主张下等效；选哪种是仓库风格问题（本仓 core 一律用 `#ifndef`）。
- 本条覆盖 C++17（clang/`#pragma clang fp contract` 环境）实测；`inline` 变量是 C++17 起才有的特性。

## 失败信号（未来命中即该想起本条）

编译报 `error: redefinition of '<符号>'`，而被重复定义的符号明明是 `inline` / `inline constexpr` 且定义在头文件里 → 先查该头文件有没有 include guard。
