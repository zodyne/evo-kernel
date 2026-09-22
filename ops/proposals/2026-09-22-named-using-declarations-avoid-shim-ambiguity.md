---
id: named-using-declarations-avoid-shim-ambiguity
type: lesson
status: candidate
scope: global
domain: cpp
tags: [cpp, using-directive, using-declaration, libm-shim, ambiguity]
triggers:
  - "消费者/测试 TU 需要核心命名空间里的类型名（Real_t/ComplexF_t 等）可见，但 `using namespace <ns>;` 会让未限定 libm 调用二义"
  - "要评估把 using-directive 换成逐条 `using ns::X;` 能否消掉 call to 'fabs' is ambiguous"
  - "TU 只需要命名空间里的类型别名/枚举，不需要它的函数重载，却被迫引入整个命名空间（失败信号）"
  - "复核『必须逐处改调用点才能消二义』的修法，想找只改声明区的机械解"
created: 2026-09-22
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-5f94-7475-af70-36af963834d5
last_verified: 2026-09-22
superseded_by: null
schema_version: 1
related: [using-directive-vs-shim-namespace-ambiguity, using-declaration-conflicts-with-shim-in-namespace, libm-shim-include-demote-from-common-header]
---

# 把 `using namespace <ns>;` 换成命名 using 声明，可同时保住未限定类型名与消除 libm 二义

**主张**：消费者 TU 需要核心命名空间里的类型/枚举时，用逐条命名 using 声明（`using amw::Real_t;` 这类，每 TU 15 条）替代整条 `using namespace amw;`，测试体其余不动：变体 A 对 24 个测试文件各加一批命名声明后，逐 TU 编译从基准的二义变成 `ambiguous=0 all_errors=0`。原因：using 声明只把清单里列出的类型/枚举引入作用域，不把 `amw::sin/fabs` 加进未限定调用的候选集。

**为什么**：`call to 'fabs' is ambiguous` 来自未限定调用同时看到全局候选与核心命名空间里的遮蔽重载。using-directive 是「把该命名空间所有成员放进候选集」的全量引入；命名 using 声明是「只引入我点名的那几个成员」。只要 TU 不需要遮蔽层的函数，点名引入类型就能既保留 `Real_t x;` 这样的未限定写法，又不触发二义。

**证据（本会话切片，命令 ↔ 结果）**：

- 构造：`rm -rf va && cp -R repo va && python3 variant_a.py va` → `tests/integration/test_doa_beam.cpp named_usings=15`（每个测试 TU 15 条）。
- 注入内容（`grep -n '^using amw::' va/tests/unit/test_eig.cpp`）：`18:using amw::ComplexF_t; 19:using amw::Real_t; 20:using amw::eOk; 21:using amw::…`。
- 编译：`./compile_all.sh va 2>&1 | tail -28` → `tests/integration/test_doa_beam.cpp ambiguous=0 all_errors=0`（对照基准 v0 同格式输出是 `ambiguous=5 all_errors=5`）。
- 改动面核对：`=== va vs repo (tests only) === changed files: 24`（只改测试声明区，未动调用点）。

**边界 / 反例**：

- 前提是 TU 不依赖遮蔽层的函数：如果测试原本要靠未限定的 `sin/fabs` 走 shim 语义，换成命名声明后会静默改用标准库版本（行为变化），这种情况下不能这样改。
- 命名清单必须覆盖该 TU 所有未限定的核心符号引用；漏一个就是 `use of undeclared identifier`（本会话变体 D 的失败形态，见 related）。
- 15 条/TU、24 个文件是当次快照；不同 TU 的清单要各自生成并逐 TU 编译验证。
- 切片里 va 的编译输出被 `tail -28` 截断，只保留了开头若干 TU 的 `ambiguous=0` 行；全量 24 TU 的逐行清单未完整落在切片里。

**失败信号（未来命中即该想起本条）**：为了让消费者看见核心类型名而大批量注入 `using namespace`，随后出现 libm 二义；或有人把「消二义」等价于「必须逐处改调用点」。
