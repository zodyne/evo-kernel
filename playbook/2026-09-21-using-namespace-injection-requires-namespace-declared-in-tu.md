---
id: using-namespace-injection-requires-namespace-declared-in-tu
type: lesson
status: validated
scope: global
domain: cpp
tags: [cpp, using-directive, namespace, bulk-edit, compile-error]
triggers:
  - "按 glob 给一批头文件/源文件批量注入 `using namespace <ns>;`"
  - "编译报 error: expected namespace name，指向刚注入的 `using namespace ...;` 行（失败信号）"
  - "被注入的文件只 include 标准库头，没有 include 任何声明该命名空间的核心头"
  - "复核『对所有 tools/xxx/*.{hpp,cpp} 都加 using namespace』这类按字面全量执行的动作"
  - "少数文件不满足注入前提，纠结该跳过注入还是给它补 include"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-60e8-7475-af70-36b8b52e029c
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [using-directive-vs-shim-namespace-ambiguity, zero-include-header-still-has-includers, cpp-namespace-wrap-must-follow-last-include]
---

**主张**：`using namespace X;` 注入到某个翻译单元时，若该 TU（经它包含的头链）根本没有声明 `X`，编译会直接失败（Apple clang 实测 `error: expected namespace name`），不是「多引入一点重载候选」的软风险。按 glob 批量注入前必须按「该文件是否（间接）包含声明该命名空间的核心头」分档：不满足前提的文件要么跳过注入，要么先补相应 include；按字面全量注入必然在少数「零核心头」文件上炸。

**为什么**：using-directive 的前提是名字查找能找到那个命名空间；纯标准库 TU 里 `amw` 这个名字从未被声明，编译器在解析 using 行时就直接报错。这类文件在批量扫描里往往只占少数（本例 parity 目录里唯一一个），所以「先跑一个文件试试」或「按目录整体看」都看不到它。

**证据（切片命令 ↔ 结果）**：

- 施工脚本按 glob 执行注入后（同批输出 `patched headers wrapped: 32 extern-open removed: 29 extern-close removed: 29 cpp wrapped: 25 …`），构建 parity 目标：
  `cmake --build build --target parity -j1` ↳ `parity rc=2 1 4:/tmp/review-scan-tests/repo/tools/parity/decoder.hpp:16:17: error: expected namespace name`。
- 该文件正是「零核心头」形态：`tools/parity/decoder.hpp` 只 include `<cstddef>/<string>`，不包含任何 core 头（末条 assistant 复核结论：parity 目录里唯一不包含任何 core 头的头文件；动作 7 字面要求对 `tools/parity/*.{hpp,cpp}` 都加 `using namespace amw;`）。
- 处置与复验：`sed -i '' '/^using namespace amw;$/d' repo/tools/parity/decoder.hpp && cmake --build build --target parity -j1` ↳ `parity rc=0 0`。

**边界 / 反例**：

- 报错形态依赖编译器：本会话是 macOS Apple clang 的 `error: expected namespace name`；GCC 同类语义的文案不同，别只按字面 grep 这一句认定「不是同一个错」。
- 「包含声明该命名空间的头」不等于「本文件直接写了 include」——间接包含也算；分档要按预处理后的名字可见性，不能只数本文件 `#include` 行里的核心头（见 `zero-include-header-still-has-includers` 的出入度区分）。
- 跳过注入只是让编译通过；该文件是否本应适配新命名空间（即是否漏了一个该改的文件）是另一个判断，不由本条回答。

**失败信号（未来命中即该想起本条）**：批量注入 `using namespace X;` 后，编译在某个只 include 标准库的文件上停在 `expected namespace name`；或复核清单里出现「该目录所有文件都加」而其中个别文件不含核心头。
