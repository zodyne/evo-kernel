---
id: 2026-09-16-tiarmclang-subtarget-cortex-r5-not-r5f
type: lesson
status: validated
scope: global
domain: embedded-toolchain
tags: [tiarmclang, ti-cgt, cortex-r5, cross-compile]
triggers:
  - "tiarmclang 编译报 subtarget not supported"
  - "给 TI Cortex-R5F / M4F 核交叉编译，不知道 -mcpu 该写什么"
  - "tiarmclang -mcpu=cortex-r5f 报错"
  - "验证 TI 编译器产物架构时拿不准用哪个 -mcpu"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7f9-4ced-73b3-8cfc-3829cc92108c
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: []
---

tiarmclang（TI CGT ARM LLVM 4.0.2.LTS）不接受 `-mcpu=cortex-r5f` 子目标（报 `subtarget cortex_r5f not supported`），要用 `-mcpu=cortex-r5`；本会话 `-mcpu=cortex-r5f` 报错、`-mcpu=cortex-r5` 产出 `ELF 32-bit LSB relocatable, ARM, EABI5` 的 .o。

为什么：TI 的 ARM LLVM 前端子目标命名不沿用 GCC 的 `-f` 后缀约定（cortex-r5f / cortex-m4f 这种带 FPU 后缀的写法在 tiarmclang 里非法），合法取值要用 `/opt/ti/ti-cgt-armllvm_4.0.2.LTS/bin/tiarmclang` 打印的 `-mcpu` 支持列表为准。

边界/反例：别靠「编译通过了」判断产物架构对不对——`-mcpu` 写错可能静默 strip 某些 CPU 特性而非报错；验证用 `readelf -h` / `file` 看产物的 ELF 架构与 EABI 版本，而不是只看编译器版本号。
