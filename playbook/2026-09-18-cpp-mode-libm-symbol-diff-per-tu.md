---
id: cpp-mode-libm-symbol-diff-per-tu
type: lesson
status: validated
scope: global
domain: porting
tags: [libm, symbol-table, cpp17, c-to-cpp, bit-exact, per-tu-diff]
triggers:
  - "把 C 算法库切成 C++17 编译，想声称『只换语言、数值路径没变』"
  - "逐位/字节级 golden 闸门在 C++ 编译模式下失效，却看不出哪一级被换了实现（失败信号）"
  - "同一份 .c 用 cc 与 clang++ -x c++ 编出的 .o 不一样，判断这是否影响数值"
  - "想定位 core 里哪些 TU 在 C/C++ 两种模式下调用了不同的数学库符号"
  - "位等价验收只做了端到端对拍，没有中间层/符号层的差异清单（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af35-8863-7097-91f3-80ea6b63439a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [mmw-cpp17-port-golden-equivalence, fma-contraction-invalidates-bitwise-acceptance-gates]
---

## 主张

同一份 `.c` 源码交给 C++17 编译器（`clang++ -x c++ ...`）编译，产出的目标文件**不是**逐字节相同的（实测 `objects byte-identical: NO`），而且**数学库调用符号会按 TU 改变**：所以「只换编译语言、没改源码 ⇒ 数值路径不变」不成立。要声称位等价，必须先做**逐 TU 的 libm 符号表比对**把差异钉到具体调用行，不能只靠端到端 golden 兜底——因为端到端 golden 只会在差异已经放大到影响输出时才报警。

## 证据（切片命令 ↔ 结果）

1. 同源双编目标码对比（4 个代表 TU）：
   `for f in core/src/dpu/doa/beam.c core/src/dpu/doppler/ddm.c core/src/dpu/doa/music.c core/src/math/fft.c; do o1=...; o2=...; cmp ...`
   → `--- beam.c ---  C math syms: _cos _sin   C++ math syms: _cos _sin   objects byte-identical: NO (expected: symbol na…[切片截断])`
   —— 注意：**符号集合相同但对象仍不同**，说明「对象不同」本身不是判据（代码生成差异属预期），有判别力的是下一步的符号表。
2. 全 core 逐 TU 的 libm 符号表（模式 `^_(sin|cos|…|fmod)[fl]?$`）：
   打印表头 `TU / C-libm / C++-libm / DIFF?`，行首 `dpu_doa_music.c   _sin …[切片截断]`。
3. 定位差异点：`echo "=== the single divergence site ===" && rg -n "\bsin\s*\(|\bcos\s*\(" core/src/dpu/doa/music.c`
   → `166:  Real_t xSa = ( Real_t ) sin( xAzDeg * ( Real_t ) M_PI / ( Real_t )…`
   —— 差异收敛到 `dpu_doa_music.c` 的 `music.c:166` 这一处 `sin(...)` 调用。

## 反例 / 边界

- 切片把符号表正文截断了：**C++ 侧具体落到哪个 libm 符号（如 double 版 vs float 版）本会话未打印**，本条只主张「存在差异点且可逐 TU 定位」，替换成哪个实现待复验。
- 逐 TU 手编的探针（`clang++ -x c++ -c`）与 CMake 实际构建的编译选项不必相同；符号表会随 `-O`/`-ffast-math`/`-std=` 变化，比对两侧必须锁死同一组选项。
- 端到端逐位对拍仍然需要（见 `bytes-exact-oracle-gate-for-pipeline-port` 与 `mmw-cpp17-port-golden-equivalence`），本条只是它的**前置定位手段**：对拍失败时先看这张表，而不是逐级加打印。

## 失败信号（未来命中即该想起本条）

- 逐位闸门在 C 版过、切到 C++ 编译后不过，而源码 diff 为空。
- 看到「对象文件不相同」就断言实现变了；或反过来看到「符号集合相同」就断言数值没变。
- 迁移报告里只有「25/25 TU 编过、ctest 全绿」，没有任何符号级/调用点级的差异清单。
