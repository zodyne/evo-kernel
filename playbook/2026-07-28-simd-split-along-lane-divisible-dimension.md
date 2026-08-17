---
id: simd-split-along-lane-divisible-dimension
type: lesson
status: deprecated
scope: global
domain: performance
tags: [simd, neon, vectorization, arm, c, numerical, bit-exact]
triggers:
  - "给一个嵌套循环做 NEON/SIMD 向量化，且要求结果与标量版逐位一致"
  - "某条维度长度不是 lane 宽（4/8）的倍数，纠结沿哪条维度切"
  - "向量化后想保证数值 bit-exact，担心浮点累加顺序改变导致漂移"
  - "沿通道/内层切 lane 导致浪费或对齐错位（失败信号）"
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:fb616292-c015-42e4-9987-16229ad221f3
last_verified: 2026-07-28
superseded_by: skill:embedded-cross-compilation
schema_version: 1
---
# SIMD 沿"能整除 lane 宽"的维度切，可与标量版逐位一致

**主张**：做 SIMD 向量化时，应沿**长度能整除 lane 宽**的维度切分，并且能做到与标量版**逐位一致**——方法是让每条 lane 内部仍按标量版的累加顺序执行。沿不能整除的维度切会浪费 lane，还可能改变浮点累加顺序、破坏 bit-exact。

**根因（UCM221 rho 网格搜索实例）**：运算是 M 个格点 × 6 通道的内积。沿通道切：6 不是 4 的倍数，lane 装不满且跨 lane 累加顺序被打乱；沿格点切：把 M 个格点拆成 4 路，每条 lane 内部仍按 m=0..5 的同一顺序累加，与标量逐步一一对应，故逐字节相同。

**修法**：优先把外层（长且可整除）维度并行化，内层保持标量原序；若必须沿短维度切，接受可能非 bit-exact 并单独验证。

**反例/边界**：若算法对累加顺序不敏感（整数/可结合），沿哪条切都行，此约束主要针对要求 bit-exact 的浮点移植。

**证据**（session fb616292）：
- 逐位一致验证：`cc ... -DfafNO_NEON`（标量）与 NEON 版逐点 diff → `[PASS] 320 行逐点向量 + 500 帧计数 逐字节相同 —— NEON 与标量逐位一致`。
- 实测加速：`make bench` 跨 n_grid=51/31/21/15/11 给出 `features` 耗时与 NEON 加速比；PORTING 预算表据此更新为 NEON 实测值。
- 捕获：`inbox/capture-2026-07-28-06-10-06-884-mg1k.md`。
