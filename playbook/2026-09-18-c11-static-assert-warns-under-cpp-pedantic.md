---
id: c11-static-assert-warns-under-cpp-pedantic
type: lesson
status: validated
scope: global
domain: build-system
tags: [static-assert, c11, pedantic, cpp17, porting, warnings]
triggers:
  - "把 C 头文件/源码按 C++17 编译，头里有 C11 的 _Static_assert"
  - "C→C++17 迁移声明『零告警』，但加上 -pedantic 后冒出 warnings（失败信号）"
  - "编译日志出现 '_Static_assert' is a C11 extension [-Wc11-extensions]"
  - "移植后要开 -Wpedantic / -Werror 做严格验收，先要清掉语言方言类告警"
  - "同一份头文件要同时给 C 与 C++ 编译器吃，断言宏要按语言分支"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af35-8863-7097-91f3-80ea6b63439a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [mmw-cpp17-port-golden-equivalence, cmake-project-languages-must-list-cxx]
---

## 主张

C11 的 `_Static_assert` 在 `-x c++ -std=c++17` 下**能编过**（clang 接受），但一开 `-pedantic` 就会报语言方言告警：`'_Static_assert' is a C11 extension [-Wc11-extensions]`。因此「C→C++17 迁移零告警」这个结论只在没开 `-pedantic` 的前提下成立；要做严格验收（`-Wpedantic -Werror`）必须先把头文件里的 `_Static_assert` 换成 C++ 的 `static_assert`（或按 `__cplusplus` 分支）。

## 证据（切片命令 ↔ 结果）

命令：逐 TU 以 C++ 模式加 pedantic 选项编译 core 源码，输出重定向到 `/tmp/wped.txt`
（`for f in $SRCS; do clang++ -x c++ -std=c…; done`）
结果：
```
=== pedantic warnings ===
core/include/core/types/radar.h:114:1: warning: '_Static_assert' is a C11 extension [-Wc11-ext…]
```
即：告警来自**公共头** `core/include/core/types/radar.h:114`，会被所有包含它的 TU 传染。该告警只在开了 pedantic 的这次普查里出现——同会话另一次按类别统计的告警普查曾得出 `total warnings: 0`（该次普查的开关集合在切片里被截断，不能据此断言两者口径相同）。

## 反例 / 边界

- 只在「同时开 C++ 模式 + `-pedantic`」时出现；纯 C 编译（`-std=c11`）下 `_Static_assert` 是本语言标准写法，不该改。
- gcc/clang 版本与 `-std=` 取值会影响该告警是否升级为 error；本条的现象记录于 Apple clang 17.0.0 / `-std=c++17`。
- 换写法时注意兼容面：`static_assert` 在 C11 里要通过 `<assert.h>` 的 `static_assert` 宏才可用，若头文件要同时服务 C11 与 C++17，应按 `__cplusplus` 分支而不是无条件替换。

## 失败信号（未来命中即该想起本条）

- 迁移报告写「0 warning 通过」，但验收命令里其实没带 `-pedantic`；一加就红。
- 加 `-Werror` 后构建突然挂在某个公共头的宏展开处，报的是方言扩展而非真实缺陷。
