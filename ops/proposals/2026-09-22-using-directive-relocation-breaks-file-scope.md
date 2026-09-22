---
id: using-directive-relocation-breaks-file-scope
type: lesson
status: candidate
scope: global
domain: cpp
tags: [cpp, using-directive, namespace, scope, unknown-type-name, design-card-preflight]
triggers:
  - "给消费者 TU 注入 `using namespace <ns>;` 后想用『把 using 挪进 main()/函数体』来消二义"
  - "把文件级 using-directive 收窄到函数作用域后编译报 unknown type name '<X>_t'（失败信号）"
  - "批量改造中要决定 using 指令放文件作用域还是函数作用域"
  - "复核『using 指令造成二义』的修法，需要先确认该 TU 文件作用域有没有未限定的核心类型/别名声明"
  - "编译错误不再落在调用点，而落在 main() 之前的声明行（失败信号：症状从 ambiguous 变成 unknown type name）"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-5fdc-7475-af70-36b1e6d248da
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [using-directive-vs-shim-namespace-ambiguity, using-namespace-injection-requires-namespace-declared-in-tu, cpp-namespace-wrap-must-follow-last-include]
---

# 把 `using namespace` 从文件作用域挪进 `main()` 不是消二义的无痛修法：文件作用域的未限定引用会立刻变成 `unknown type name`

**主张**：给消费者 TU 注入 `using namespace <核心命名空间>;` 引发二义（见 related）之后，把同一行**从文件作用域收窄到 `main()`/函数体**会引入另一类编译失败：该 TU 文件作用域里用未限定名写的声明（全局对象、类型别名、函数签名）不再能解析到被移走的作用域成员，编译在 `main()` 之前的那些行直接报 `unknown type name`。本会话实测该变体在 `test_eig.cpp` 第 21 行即失败。收窄 using 不是等价改写，动手前要按 TU 逐个确认文件作用域是否有未限定引用。

**为什么**：using-directive 的可见性严格跟着它出现的作用域走。文件级 using 被移进函数体后，函数体外的名字查找不再能看到该命名空间成员；而测试 TU 常在文件顶部声明依赖核心类型（全局 fixture、别名、辅助函数签名），这些位置没有任何限定词，于是先在声明行炸掉——二义问题还没走到。

**证据（本会话切片，命令 ↔ 结果）**：

- 变体构造：在 `/tmp/review-blockB-live` 的仓库副本上做 `rm -rf ce_onfile && cp -R repo ce_onfile && python3 …`（切片命令被截断），目标文件为 `ce_onfile/tests/unit/test_eig.cpp`。
- 结果：`=== test_eig.cpp: using moved inside main() only === ce_onfile/tests/unit/test_eig.cpp:21:8: error: unknown type name 'C…`（切片在此截断类型名）。
- 同批对照：文件级 `using namespace amw;` + D10 式 libm 头的另一路实验报的是 `call to 'fabs' is ambiguous`（如 `minimal_final.cpp:6:16`）——两种作用域各有各的失败形态，收窄并没有消掉原问题。

**边界 / 反例**：

- 本条只覆盖「文件作用域确有未限定引用」的 TU；若某 TU 的全局声明本来就写 `amw::X` 限定名，收窄 using 不会因此报错（函数体内调用是否仍二义另行判定）。
- 切片只给出 `test_eig.cpp` 一个 TU 的实测；「其它 TU 也一定失败」未逐份验证，需按 TU 编译确认。
- 类型名在切片输出里被截断为 `'C…`，本条不补全具体类型名；也不主张「该怎么修」（逐处限定调用 / 不放 using / 改遮蔽层均属设计决策）。
- 更一般的注入前提（TU 是否 include 了声明该命名空间的头）见 related 的 `using-namespace-injection-requires-namespace-declared-in-tu`；本条是同一批机械动作的另一个失败面。

**失败信号（未来命中即该想起本条）**：机械挪动 using 作用域后，编译错误从调用点的 `ambiguous` 变成 `main()` 之前声明行的 `unknown type name`；或有人声称「把 using 收窄进函数就能消掉 libm 二义」。
