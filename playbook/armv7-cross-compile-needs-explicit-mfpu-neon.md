---
id: armv7-cross-compile-needs-explicit-mfpu-neon
type: bullet
status: validated
scope: global
domain: performance
tags:
- armv7
- neon
- cross-compile
- compiler-flags
- silent-fallback
triggers:
- 交叉编译 ARMv7 目标，NEON 加速路径用 __ARM_NEON 宏守卫
- 交叉编译产物功能正确但性能与标量版一样（失败信号）
- NEON intrinsic 代码编不过或被静默跳过
- 验收交叉编译的向量化改造，先确认 NEON 路径真的编进去了
created: 2026-08-12
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: 人工（整理 inbox/capture-2026-07-28-06-10-06-884-mg1k.md）
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related:
- simd-split-along-lane-divisible-dimension
- neon-vmlaq-f32-not-portable-bit-exact
---
# ARMv7 交叉编译必须显式 `-mfpu=neon`，否则静默退回标量版

**主张**：交叉编译 ARMv7 目标时，**必须显式传 `-mfpu=neon`**。不传则 `__ARM_NEON` 宏不定义，所有 `#ifdef __ARM_NEON` 守卫的 NEON 路径被静默剪掉，编出来的是标量版——编译无报错、功能正确，只是加速完全没有。

**为什么**：这是"配置未生效但产物看似正常"的静默失效：功能测试全绿，只有性能/符号检查能暴露。验证方式：查预定义宏（`echo | cc -dM -E -mfpu=neon - | grep NEON`）或对产物 `nm`/`objdump` 确认 NEON 符号真的编进去了。

**反例/边界**：aarch64 目标 NEON 是架构标配、无需此 flag；仅 ARMv7（32 位）交叉编译有此坑。

**证据**：capture-2026-07-28-06-10-06-884-mg1k（UCM221 NEON 移植，ARMv7 交叉编译实测）。
