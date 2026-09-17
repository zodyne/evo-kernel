---
id: mmw-cpp17-port-golden-equivalence
type: lesson
status: candidate
scope: global
domain: signal-processing
tags: [golden, bit-exact, memcmp, porting, cpp17, algommw, hann, beamforming]
triggers:
  - "把 C 算法库（algommw/core）移植到 C++17，要与原实现做 golden 等价比对"
  - "浮点逐级比对用 == 无法区分 ±0，想按位模式比较"
  - "beam 1D/2D 自判把 12 虚拟阵元判成 1D，multiPeak/angleInterp 报 NotImplemented（失败信号）"
  - "algommw 的 Hann 窗系数对不上（64 点 CG=0.4922 而非 0.4980）"
  - "C 端该直接 include C 头还是手抄 C 结构体声明"
created: 2026-09-09
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-09-06-07-07-764-obaf
last_verified: 2026-09-09
superseded_by: null
schema_version: 1
related: [bytes-exact-oracle-gate-for-pipeline-port, dual-impl-cross-check-tolerance-grid-anchored]
---

# 主张

mmw（C++17 移植 `algommw/core`）的 golden 等价测试一次通过的可复制做法：

1. 两侧同驱同一合成帧（确定性 LCG 噪声 + 注入目标），每级（range/cube、doppler/rdmap、cfar、doa、cluster、track、toWorld）float 按 `memcpy` 取位模式比较，不用 `==`（以区分 ±0）。
2. C 端直接 include C 头（自带 `extern C` 守卫）+ 链 `libcore.a`，不手抄 C 结构体声明，零布局假设。
3. 双侧 init 都失败也是通过的一种——行为一致即等价。

# 同批实测的两个坑

- **beam 1D/2D 自判**：判据是 posZ 极差 < 0.25 → 1D。12 虚拟阵元（3tx×4rx）只占 z 行 0..2，行距 0.09 时跨度 0.18，被判成 1D，`multiPeak`/`angleInterp` 直接 `NotImplemented`；行距须 ≥ 0.125（0.13 安全）才算 2D 阵。
- **Hann 窗**：algommw 的 Hann 是周期窗（`w[0]=w[N-1]=0`），64 点 CG=0.4922=(N-1)/N/2，不是对称窗的 0.4980。

# 证据

上述三种做法与两个坑的数值均来自同一次 golden 等价测试（双侧同驱合成帧、逐级 float 位模式比较）。
