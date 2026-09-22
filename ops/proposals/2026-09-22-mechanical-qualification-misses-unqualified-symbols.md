---
id: mechanical-qualification-misses-unqualified-symbols
type: lesson
status: candidate
scope: global
domain: refactoring
tags: [cpp, using-directive, namespace-qualification, bulk-edit, undeclared-identifier]
triggers:
  - "把 `using namespace <ns>;` 换成按清单逐处 `ns::` 限定的机械改写"
  - "改写后编译报 use of undeclared identifier，符号原先靠 using-directive 才可见（失败信号，本会话是 eModTdm）"
  - "变体脚本只汇总 qualified=N 这类改写计数，想据此下『改写完备/等价』结论"
  - "决定用逐符号限定还是保留 using-directive 来适配命名空间包裹后的代码"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-5f94-7475-af70-36af963834d5
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [using-directive-relocation-breaks-file-scope, mechanical-identifier-rename-cascades, named-using-declarations-avoid-shim-ambiguity]
---

# 逐符号 `ns::` 限定不是 using-directive 的等价替换：清单外的未限定引用会变成 undeclared identifier

**主张**：把 `using namespace amw;` 换成「按核心符号清单逐处加 `amw::` 前缀」的变体 D，在 `vd/tests/unit/test_cfar.cpp:30:29` 报 `use of undeclared identifier 'eModTdm'`——该符号原先靠 using-directive 可见、不在限定清单里，替换后没有任何声明接住它。机械限定只有在符号清单完备时才算等价改写；不完备时失败形态是 `use of undeclared identifier`（不是二义），必须逐 TU 编译收敛，变体脚本的改写计数不能当编译证据。

**为什么**：using-directive 的可见性是「该命名空间全部成员」；逐处限定是「清单 ∩ 出现处」。以类型名/正则生成的清单天然抓不全所有被未限定引用的实体（常量、枚举量、函数、模板等命名不统一），漏网者在编译期直接 undeclared。失败点会分散在各 TU，只有逐 TU 编译能全量暴露。

**证据（本会话切片，命令 ↔ 结果）**：

- 变体构造：`##### Variant D (qualify core symbols with amw:: only) ##### … python3 variant_d.py vd`（其汇总行在切片中被截断于 `qua…`）。
- 逐 TU 编译（`for f in vd/tests/unit/test_cfar.cpp vd/tests/unit/test_range.cpp; do … clang++ -std=c++17 -fsyntax-only …`）→ `===== vd/tests/unit/test_cfar.cpp ===== vd/tests/unit/test_cfar.cpp:30:29: error: use of undeclared identifier 'eModTdm'`。

**边界 / 反例**：

- 切片只展示 `test_cfar.cpp` 的一个错误（循环里第二个 TU 的结果被截断）；「还有哪些符号/TU 漏掉」未穷举，处置时要自己按编译错误收敛。
- `eModTdm` 的实体类别在切片里未展示（其命名符合同库 `e` 前缀常量约定）；这不影响本条主张：任何被未限定引用且不在清单里的名字都会同样失败。
- 若清单生成器是完备的（先收集全部被未限定引用的标识符再限定），或改写保留 using-directive 兜底，则不会触发该失败；本条不主张「限定法不可用」，只主张它需要编译验证。

**失败信号（未来命中即该想起本条）**：命名空间适配改写后出现 `use of undeclared identifier '<奇怪小写名>'`，而该符号既没被删也没被改名；或改写汇总只报 `qualified=N` 就准备声称与 using-directive 等价。
