---
id: capture-2026-08-17-145320-matlab-hanning-classic-definition
type: fact
status: inbox
scope: global
domain: matlab-python-migration
tags: [matlab, fft, window, golden-diff]
triggers:
  - "MATLAB 移植窗函数 hanning"
  - "hanning 与 scipy hann 数值对不上"
  - "FFT golden 差分 0.4% 但公式相同"
  - "numpy/scipy 窗函数选型"
created: 2026-08-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:hermes-afm761-matlab-to-python-migration
last_verified: 2026-08-17
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored]
---

MATLAB 内置 `hanning(N)` 是**经典定义** w[n] = 0.5*(1 - cos(2π(n+1)/(N+1)))，n=0..N-1，端点非零（N=512 时 w[0]=w[511]≈3.75e-5），峰值 1 不在样本点上；这与 scipy/numpy 的 `hann(sym=True)`（0.5*(1-cos(2πn/(N-1)))，端点为零）是**两个不同的窗**。实测：AFM761 range-FFT 用两种窗的 golden 差分达 0.4%（FFT 输出量级 1e8 时差 3.5e-9 绝对量级的伪结论不成立——实际是窗本身不同），对 golden 等效窗做最小二乘反解（768 个 DC-bin 方程 × 512 未知）残差 ~2e-9 机器精度，确认 MATLAB 用的是 N+1 分母经典式。移植 MATLAB 信号处理链时，内置窗函数必须逐字复刻 MATLAB 定义，不能按名字映射到同名 numpy 函数；反之，.m 文件里自定义的局部窗函数（如 symmetric_hann）才按对称定义实现。识别方法：两端点是否严格为 0（对称定义）或 ~1e-5 级非零（经典定义）。
