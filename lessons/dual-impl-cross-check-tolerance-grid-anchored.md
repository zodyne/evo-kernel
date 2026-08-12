---
id: dual-impl-cross-check-tolerance-grid-anchored
type: lesson
status: candidate
scope: global
domain: signal-processing
tags: [cross-validation, verification, doa, fft, independent-implementation, radar]
triggers:
  - "从零验证/复现一条信号处理算法链（测角、CFAR、点云）的正确性"
  - "怀疑参考实现有 bug，需要一个不共因的对照实现"
  - "两个实现结果'看起来差不多'，缺一个数值化的通过判据"
  - "对拍发现系统性偏差（符号约定/单位/网格量化错误信号）"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fab8d-651f-7df8-8d1d-29c7d2f71bce
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [bytes-exact-oracle-gate-for-pipeline-port]
---

**主张**：验证一条信号处理链，用**数学上独立的第二实现**（如直接相位公式 vs FFT 谱峰搜索）对同一数据复算并逐点对拍；通过判据**锚定在数值分辨率量级**（FFT 网格、量化步长），不是"趋势一致"。两实现只有在"零知识复算"级别一致，才能排除共因 bug。

**证据**（ucm221 暗室测角链从零复现，均命令输出）：① 从零链 vs core 参考链交叉验证：6 通道相位差 `[2.7e-15, 1.1e-08, 5.3e-07, ...]`°，机器精度级；② 解耦自检：直接相位 `v=-0.47954` vs 谱峰法 `v=-0.47996`，偏差 `0.00042 < FFT 网格 0.00195`；③ 独立重算（直接相位公式）vs 缓存 npz（FFT 谱峰法）逐点表格对拍——正是对拍暴露了 y 符号约定错误（修正后残差落到网格内）。

**边界**：与 `bytes-exact-oracle-gate-for-pipeline-port`（移植管线对 golden 输出逐字节比对）互补：本条用于**没有 golden**、算法正确性本身待证的场景，对照物是第二实现而非历史输出。两实现若共享同一错误假设（如同一份错误的阵列布局表），对拍一致也不证明正确——独立要独立到假设层。
