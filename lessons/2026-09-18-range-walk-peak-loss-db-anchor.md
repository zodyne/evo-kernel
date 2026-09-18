---
id: range-walk-peak-loss-db-anchor
type: lesson
status: candidate
scope: global
domain: radar-signal
tags: [fmcw, range-walk, range-migration, 2d-fft, peak-loss, sanity-check]
triggers:
  - "估算距离走动 / 帧间迁移带来多少 dB 峰值损失、要不要补偿"
  - "核验简报里『每帧走 0.56 个距离 bin，K 帧不补偿就 smear』的量化影响"
  - "探针算出的走动峰值损失是几十 dB（失败信号：与 dB 级小量的量级锚差一个数量级）"
  - "同一走动量两次探针结果对不上（如 -35.73 dB vs -2.58 dB），要判断信哪个"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a5ef-73cf-777c-a410-325b695c9961
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [noncoherent-multiframe-align-integer-bin-shift, motion-chain-selftest-needs-nonzero-velocity-r-conservation, cross-frame-range-gate-must-track-target]
---

# 走动损失的 dB 量级锚：CPI 内总走动 0.5635 bin 只值 2.58 dB（2D FFT 峰值口径）

## 主张

单帧/CPI 内总距离走动 `D` 个 bin 造成的峰值损失是 **dB 级小量**，不是几十 dB。Nc=128、Ns=1024 的 2D FFT 峰值口径实测（rect/rect）：`D=0.25 → -0.52 dB`、`0.5 → -2.04 dB`、`0.5635 → -2.58 dB`、`1.0 → -6.92 dB`。本项目参数（`T_frame=7.680 ms`、`dR=0.7495 m`）下 55 m/s 单帧走动 `0.4224 m = 0.5636 bin`，对应单帧走动损失就是 ~2.6 dB。评估走动影响时先拿这条曲线当量级锚；报数时把 `D` 的口径（**CPI 内总走动量**，不是每步/每 chirp 增量）与归一化方式一并写出，否则同一次会话里同一组走动量能分别算出 `-35.73 dB` 与 `-2.58 dB`，差 33 dB。

## 为什么

"走动损失"这一条曲线的绝对值完全由口径决定：D 是逐步长增量还是整段总迁移、峰是取 1D 距离剖面最大还是 2D (range, Doppler) 平面的最大、有无归一化，都会让同一个物理量换个数量级。人们记住的又往往是"走动会 smear"这个定性结论，于是几十 dB 的读数不会与直觉冲突，静默错一个数量级也没人拦——所以需要一条钉死的量级锚。

## 证据（切片命令 ↔ 结果）

- 修正口径的 2D FFT 峰值损失曲线（输出头明写 `total range walk D (bins)`）：
  `== 2D FFT peak loss (corrected) ==   rect/rect      D=0.25:-0.52  D=0.5:-2.04  D=0.5635:-2.58  D=1.0:-6.92   hann/hann …`（`hann/hann` 之后被切片截断，引用该段需按同一探针重跑）
- 同会话首版探针（同 Nc=128/Ns=1024，跑同一组走动量 0.25/0.5/0.5635）：
  `rect      delta=0.2500  loss=-29.22 dB rect      delta=0.5000  loss=-34.98 dB rect      delta=0.5635  loss=-35.73 dB rec…`
  ——与修正版在 `0.5635` 上相差 33 dB，而只有修正版的输出头写明了 D 是 CPI 内总走动量（`vs total range walk D (bins)`）。
- 项目参数（把 bin 数和物理量对上）：`T_frame=7.680 ms  dR=0.7495 m  walk@55=0.4224 m = 0.5636 bin  T_ramp=51.2 us`。
- 同会话的 v=0 自检点：`损失= +0.00 dB | 0.000 bin`——零走动必须是 0 dB，用来确认曲线归一化正确。
- 旁证·窗响应是另一个口径（不要互相顶替）：`Δ=0.50 bin: Hann 响应 = -1.42 dB   Δ=1.00 bin: Hann 响应 = -6.01 dB`（相同量级，但那是目标落点偏离 bin 的窗损失，不是走动损失）。

## 边界 / 反例

- 数值随 Nc/Ns、窗函数、是否相干积累变化；跨项目/跨配置引用前按同一探针重跑，不要直接搬这张表。
- 走动量超过 1~2 bin 后损失不再是"小量"（本表 `D=1.0` 已 6.92 dB），长 CPI / 高速目标要按曲线外推或重算。
- 本条只给"峰值损失"这一口径；检测性能（P_d、积累增益）另算，不要拿走动峰值损失代替。

## 失败信号（未来命中即该想起本条）

- 报出的走动/迁移峰值损失是 -30 dB 量级——与 dB 级小量锚差一个数量级，先怀疑口径而非物理。
- 两张探针输出都留着、结论里引用了其中一张更"震撼"的。
- 曲线旁边没写 `D` 的定义（总走动量 vs 逐步长）。
