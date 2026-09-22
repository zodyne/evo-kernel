---
id: libm-shim-guard-arity-follows-libm-signature
type: lesson
status: validated
scope: global
domain: cpp
tags: [cpp, libm, d10, shim, arity, overload, delete, adversarial-review]
triggers:
  - "复核『libm 遮蔽 shim / D10 头形状非法（ill-formed）』类发现，要在 confirm/refuted 之间定级"
  - "给 atan2/pow/fmod/hypot 这类二元 libm 函数写同名 wrapper 探针，在定义处硬报错（失败信号：报错出在探针自己写的一元形状上）"
  - "看到 `inline double dSin(double); double dSin(float) = delete;` 这类声明型守卫，要判断它和 wrapper 定义是不是同一种形状"
  - "审计/复现 D10 的 20 个函数遮蔽形状，需要逐条按真实 arity 写声明"
  - "发现方说某 libm 形状编不过，但卡片/PLAN 原文里搜不到那个 arity 的写法（失败信号：拿改写形状指控原文）"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-edbe-7475-af70-36c4f1906a8d
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [synthetic-sandbox-mechanism-is-not-target-repo-risk, adversarial-review-repro-as-written, falsifiable-probe-for-type-tightening, using-declaration-conflicts-with-shim-in-namespace]
---

# libm 遮蔽守卫的形状按真实 arity 写声明，不是同名 wrapper 定义

## 主张

判「libm 遮蔽（D10 类）形状非法」之前，先把探针形状和卡片原文的形状在两个维度上对齐：**arity**（atan2/pow/fmod/hypot 是二元函数）与**声明 vs 定义**（卡片的编译期守卫是「按真实 arity 的声明 + delete 一个错误实参类型的重载」，没有函数体）。给二元 libm 函数写字面一元 wrapper 定义会在定义处硬报错，但那是探针自己的形状错误，不能归因给卡片；换成 arity 正确的整张声明头（20 个函数）并带一次调用，编译 rc=0。

## 为什么

二元函数的真实调用形态是两参（本会话 core 里 `atan2(dPx, dPy)`），按一元写出来的同名 wrapper 与它根本不是同一种形状；而声明型守卫不产生 wrapper 定义，走不到那条硬错误路径。用一个自己改写、少一个参数的形状去复现错误，得到的失败只能证明「改写形状编不过」，不能证明「卡片的形状编不过」。

## 证据（切片命令 ↔ 结果）

- 卡片原文形状：`rg -n "inline double|inline l…"`（P1.0b 卡）↳ M12 行 68 给出探针 `inline double dSin(double); double dSin(float) = delete;`，`dSin( xFloat )` → error（声明型守卫）。
- 真实调用 arity：`rg -n "\b(atan2|pow|fmod|hypot)\s*\(" core --glob '*.cpp' --glob '*.hpp'` ↳ `core/src/dpu/track/unit.cpp:54: pxMeas->xAzimuth = ( Real_t ) atan2( dPx, dPy );`（两参调用）。
- minprobe 变体（`/tmp/review-refute-d10-wrapper-shape-illformed-for-binary-libm/minprobe/` 下写了 `libm_min.hpp` / `use_libm.cpp` / `include_only.cpp` / `libm_fixed.hpp` / `use_fixed.cpp` / `libm_full.hpp` / `use_full.cpp`）：`D) full 20-function header, arity-correct, with call` → `rc=0`；紧接着 `E) confirm float arg still hits the delete guard`（切片在 E 的结果处截断）。
- 末条 assistant：`Reproduced the narrow technical fact: literal one-arg wrappers for atan2/pow/fmod/hypot are hard errors at the definition site`；裁决 `Verdict: not real (misreading) — isReal = false`。
- 佐证归因错位：发现方归到卡片上的短语 `20 个 inline` 在 card/PLAN 里零命中（`rg rc=1 (1=none)`）。

## 边界 / 反例

- 本条只主张「形状要按真实 arity / 声明 vs 定义核对」，不主张 D10 设计本身无风险。
- 一元 libm 函数（sin/cos/exp 这类）的守卫形状确实是一元；arity 对齐是对每个函数逐条做的，不是全表统一。
- 若卡片原文真的写了错 arity 的形状，则发现成立，不适用本条。
- verified_by=command 依据切片中的 clang++ 探针 rc 与末条 assistant 复述的硬错误结论；切片未给出完整错误文本，正文不引用具体错误串；E 的最终结果在切片中被截断，未据此下断言。
