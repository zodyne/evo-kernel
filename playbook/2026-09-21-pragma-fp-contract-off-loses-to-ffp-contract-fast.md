---
id: pragma-fp-contract-off-loses-to-ffp-contract-fast
type: lesson
status: validated
scope: global
domain: build-system
tags: [clang, fp-contract, fma, pragma, codegen, determinism]
triggers:
  - "用 `#pragma clang fp contract(off)`（或随头文件带进来的等价开关）承诺关闭 FMA 收缩，但构建命令行带 `-ffp-contract=fast`"
  - "带 pragma 与不带 pragma 的 TU 反汇编里都出现 `fmadd`，pragma 像是没生效（失败信号）"
  - "逐位/golden 对拍在 `-ffp-contract=fast` 的构建上失败，而源码里明明写了 contract(off)"
  - "要按文件/TU 关闭浮点收缩，纠结改源码 pragma 还是改构建 flag"
  - "变体构建 rc 全 0、源码只差一个 pragma，却要判浮点位型没变（失败信号：没比对生成的汇编）"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b74a-60a5-7475-af70-36b72f8c98e6
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [fma-contraction-invalidates-bitwise-acceptance-gates, include-order-flips-fp-contraction-rc-blind]
---

# `#pragma clang fp contract(off)` 在 `-ffp-contract=fast` 下不生效

## 主张

`#pragma clang fp contract(off)`（写在头文件里被 include、或写在源文件首行都一样）在 TU 以 `-ffp-contract=fast` 编译时**不生效**：生成的汇编里仍有 `fmadd`，与不带 pragma 的对照完全相同；同一个 pragma 在 `-ffp-contract=on`（C++ 默认）下确实生效（带 pragma 计数 0、不带 1）。所以「按文件/按 TU 关闭 FMA 收缩」不能只靠源码 pragma——只要构建里出现 `-ffp-contract=fast`，该 pragma 就挡不住收缩。

## 为什么

pragma 是 TU 级的浮点收缩控制，而 `-ffp-contract=fast` 允许跨语句收缩；本机 clang 实测让命令行的 fast 压过 pragma 的 off。判「pragma 有没有起作用」只能看产物（汇编里有没有 `fmadd`）：构建 rc 对指令选择零判别力，源码 diff 里也只差一行 pragma。

## 证据（切片命令 ↔ 结果）

- 环境：`Apple clang version 17.0.0 (clang-1700.4.4.1) Target: arm64-apple-darwin24.6.0`。
- 头文件携带 pragma（`pragma/fp.hpp` 内 `#if defined(__clang__) / #pragma clang fp contract(off)`）vs 不带，均在 `-std=c++17 -O2 -ffp-contract=fast -S` 下反汇编：
  `=== a.cpp (pragma) === 8: fmadd d0, d0, d1, d2 === b.cpp (no pragma) === 8: fmadd d0, d0, d1, d2` —— 两者都是 `fmadd`。
- 源文件首行直接写 pragma 的 c.cpp，在 `-ffp-contract=fast` 下计数仍为 1：
  `=== c (contract=fast) === 1 === d (contract=fast) === 1 === e (contract=fast) === 1`。
- 同一 c.cpp 换 `-ffp-contract=on`（默认）后：`=== pragma under -ffp-contract=on (default for C++) === b: 1 c: 0` —— pragma 在 on 下生效（c=0），在 fast 下不生效。
- 首轮探针对照同向：`--- with pragma, -ffp-contract=fast --- 1 --- without pragma, -ffp-contract=fast --- fmadd --- pragma warns? --- rc=0`（pragma 不产生告警，静默失效）。

## 边界 / 反例

- 仅 Apple clang 17.0.0 / arm64 实测；其他 clang 版本、`#pragma STDC FP_CONTRACT`、x86 未复验。
- 计数单位是 `-S` 汇编里 `fmadd` 的出现次数，不是运行期结果；本会话没有做运行期逐位对拍。
- 只主张「fast 命令行压倒 pragma off」这一组合；pragma 在 `-ffp-contract=on`/默认下有效（上面的 c:0 vs b:1）。
- 若构建策略是「默认允许收缩、个别 TU 用 pragma 关掉」，本条证据说明该策略在当前工具链上不成立。

## 失败信号（未来命中即该想起本条）

源码里写了 `contract(off)` 就把它当位型保证；或只有 `-ffp-contract=fast` 构建上 golden 对拍失败，却先去查算法与数据类型，而不是先数汇编里的 `fmadd`。
