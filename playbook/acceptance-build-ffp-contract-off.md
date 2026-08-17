---
id: acceptance-build-ffp-contract-off
type: bullet
status: deprecated
scope: global
domain: numerical-computing
tags: [c, fma, ffp-contract, acceptance, numerical-parity, compiler-flags]
triggers:
  - "验收期做 C 与参照实现的逐点/逐字节数值比对"
  - "C 侧结果明明更准，却被 golden 比对判 FAIL"
  - "怀疑编译器把乘加融成 FMA 改变了舍入次序"
  - "给验收/比对构建定编译选项（-O2/-O3 默认开 contraction）"
created: 2026-08-12
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: 人工（整理 inbox/capture-2026-07-27-14-36-51-742-ee3f.md）
last_verified: 2026-08-12
superseded_by: skill:matlab-to-python-migration
schema_version: 1
related: [numpy-complex-scalar-division, neon-vmlaq-f32-not-portable-bit-exact, simd-split-along-lane-divisible-dimension]
---
# 验收期编译必须 `-ffp-contract=off`：FMA 更准但不可比

**主张**：凡是要与参照实现做数值比对的验收构建，必须显式加 `-ffp-contract=off` 禁止浮点乘加融合。FMA（fused multiply-add）少一次中间舍入、结果**更准**，但与未融合的参照**不可比**——比对 FAIL 时你分不清是算法错了还是舍入路径不同。

**为什么**：验收比对的目标是"与参照同序舍入"，不是"数学上最准"。FMA 在更准的同时破坏了可比性，而现代编译器在 -O2/-O3 下默认允许 contraction，坑是静默的。

**反例/边界**：生产构建追求精度/性能、无需与参照逐点比对时，不必关 FMA；本条专指验收期（验收过后可按需放开）。

**证据**：UCM221 C 移植验收（capture-2026-07-27-14-36-51-742-ee3f），验收期编译固定 `-ffp-contract=off` 后 C 侧与 numpy 参照可比。
