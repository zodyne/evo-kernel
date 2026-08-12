---
id: neon-vmlaq-f32-not-portable-bit-exact
type: bullet
status: validated
scope: global
domain: performance
tags: [neon, simd, arm, vmlaq, fma, bit-exact, cross-arch]
triggers:
  - "用 ARM NEON intrinsic 写要求跨架构数值一致的代码"
  - "同一份 NEON 源码在 aarch64 与 ARMv7 上给出不同的数（失败信号）"
  - "为求简洁用 vmlaq_f32 做乘加"
  - "NEON 版与标量版 golden 比对出现末位差异"
created: 2026-08-12
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: 人工（整理 inbox/capture-2026-07-28-06-10-06-884-mg1k.md）
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [simd-split-along-lane-divisible-dimension, acceptance-build-ffp-contract-off]
---
# 追求跨架构 bit-exact 时禁用 `vmlaq_f32`：aarch64 融合、ARMv7 不融合

**主张**：要求 NEON 代码跨架构逐位一致时，**不要用 `vmlaq_f32`**——它在 aarch64 上被编成 FMLA（fused，乘加之间少一次舍入），在 ARMv7 上是非 fused 的，同一份源码在两个架构给出不同的数。改用 `vmulq_f32` + `vaddq_f32` 分开写，两个架构都走"乘→舍入→加→舍入"的同一路径。

**为什么**：fused 与否改变舍入次数，是编译器/架构级的静默差异，源码层面完全看不出来；UCM221 rho 网格搜索 NEON 化即靠拆分写法做到与标量版逐字节相同。

**反例/边界**：只在单架构部署、或不要求 bit-exact（容差比对）时，`vmlaq_f32` 更快更准，可以用。

**证据**：capture-2026-07-28-06-10-06-884-mg1k；NEON 版与 `-DfafNO_NEON` 标量版逐点 diff → 320 行向量 + 500 帧计数逐字节相同（验证方法详见 related 的 simd-split 条目）。
