---
id: radar-doppler-bin-wraparound-unroll-first
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: signal-processing
tags:
- doppler
- fft-bin
- wraparound
- velocity
- visualization
triggers:
- 雷达点多普勒门号（vpos）直接当速度用或着色
- 速度分布在零附近突变/两端聚集中间空（失败信号：环绕未解）
- FFT 门号接近 N-1 的点被当成速度极大
- 用波形参数推导速度标度 Δv
created: 2026-07-27
evidence:
  helpful: 0
  harmful: 0
verified_by: none
source: session:9c7257e9
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
related: []
---

# 多普勒门号是环绕量：先解环绕成有符号门号再换算速度

**主张**：FPGA/FFT 给出的多普勒门号（如 1024 点 FFT 的 0–1023）是**环绕的无符号门号**，不是速度。门 N-1 是 −1 门（微负速度），不是"速度极大"。直接用会：① 零速附近颜色/数值突变；② 负速度目标全部误判为正高速。修法：`signed_bin = bin > N/2 ? bin - N : bin`，再乘 `Δv = λ/(2·N_fft·T_c)`；标度可用自洽性校验（`N/2 × Δv` 应等于文档 V_max）。

**为什么（实测）**：0709_2 全部 195,642 点只用了 96 个门号，96.9% 落在 960–1023、1.5% 落在 0–15，中间全空——典型的未解环绕分布。解环绕后实测速度 −7.7~+17.5 m/s、中位 −4.4，物理合理。

**边界**：正负朝向哪个是靠近取决于硬件 FFT 符号约定，文档没写时在图例如实标"朝向未标定"，等实测确认后改一个符号即可，不要猜。

**证据**：session 9c7257e9，viewer_filtered.py 速度着色实现与 `Δv = 0.110896 m/s/门` 的自洽校验（512×Δv = 56.78 m/s = λ/(4T_c)）。
