---
id: m1-neon-speedup-overestimates-cortex-a9
type: lesson
status: deprecated
scope: project:ucm221-pointcloud-2-0
domain: performance
tags: [neon, cortex-a9, m1, simd-width, budget, extrapolation]
triggers:
  - "在 M1/Mac 上实测 NEON 加速比并外推到 Cortex-A9 目标"
  - "性能预算只剩零点几毫秒裕量（失败信号）"
  - "用宿主机 bench 数字做嵌入式算力预算"
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:fb616292
last_verified: 2026-07-28
superseded_by: skill:embedded-cross-compilation
schema_version: 1
---
# M1 实测的 NEON 加速比不能外推到 Cortex-A9：NEON 单元宽度差一倍

**主张**：在 Apple M1 上测得的 NEON 加速比（实测 2.31×）会系统性高估 Cortex-A9——A9 的 NEON 执行单元是 **64 位宽**（每周期 2 个 float32），M1 是 128 位。算力预算要按打折后的加速比（如 1.6×）重算，并预先排好退让顺序。

**为什么**：实测案例——faf 21 档 NEON 0.199 ms/帧（M1），×40 折算 9.9ms 勉强压进 10ms 预算，裕量仅 0.1ms；若 A9 只有 1.6×，回到 ~0.335 ms/帧，×40 = 13.4ms 仍超预算。预算表必须双列（实测值 / 保守折算值），退让方案（15 档，KEEP 交并比 90.3% 的算法代价）提前排序。

**边界**：只影响"宿主机 bench → 嵌入式目标"的外推；同架构部署无此问题。A9 实测前一切预算都是估计。

**证据**：session fb616292，`make bench` 整帧 0.245 ms/帧（21 档 NEON，M1）；NEON 与标量逐位一致（320 行向量 + 500 帧计数逐字节相同，沿格点向量化 + vmulq/vaddq 拆分写法，见 neon-vmlaq-f32-not-portable-bit-exact）。
