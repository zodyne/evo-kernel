---
id: ddm-max-radial-vel-missing-subband-factor
type: lesson
status: candidate
scope: global
domain: radar-dsp
tags: [radar, ddm, ddma, fmcw, velocity, subband, factor-error, sanity-check]
triggers:
  - "在 DDMA/DDM 波形里核对最大径向速度或最大不模糊速度的数值"
  - "DDM 解调出来的速度量级和链路配置公式算出来的对不上"
  - "最大径向速度/不模糊速度恰好差一个整数倍（如 num_subbands、num_tx），怀疑漏乘子带或发射通道数"
  - "审查 DDM 模式的速度报告路径，怀疑按单子带速度报了全局速度"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a736-0e26-7353-8a3d-4308f5b65cb2
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [radar-derived-param-mhz-hz-unit-slip]
---
# DDM 最大径向速度差 6 倍＝漏乘 num_subbands 因子，整数倍缺口是漏因子的指纹

## 主张
DDM/DDMA 波形里，最大径向速度公式含 `× num_subbands` 因子；若速度报告路径漏乘（或按单子带速度报成全局速度），
结果会**恰好差一个整数倍 = num_subbands**。本例：`xMaxRadialVel = 0.5 × num_subbands × num_doppler_chirps × λ` 实算 28.77 m/s，
DDM 实际报 4.79 m/s，`28.77 / 6 = 4.795`，正好差 6 倍 = `num_subbands = 6`。

## 为什么
漏乘一个整数因子不会抛异常，只会给出一个「量级看起来还算正常、但物理上偏小 num_subbands 倍」的速度，
容易被当成「就这个数量级」放过。偏差恰为整数倍（而非 1e3/1e6 这类量纲倍数）是「漏乘子带/通道因子」的指纹，
一眼就能和量纲滑移区分开。DDMA 的 num_subbands 通常就是 4/6/8 这类小整数，速度被它整除是强信号。

## 证据（本会话命令 ↔ 结果切片，均为实测非推测）
- `python3 -c "print(0.5*6*128*0.074915737)"` → `28.767643008`（= 28.77，公式含 `×6` 子带）。
- `core/src/chain/chain.c:131`：`xTrackConfig.xMaxRadialVel = (Real_t)(0.5 * dSubbands * (double)pxCfg->xWave.ulNumDo...` —— 链路配置公式确实乘 `dSubbands`。
- `profiles/afm761_ddm/profile.toml`：`num_subbands = 6`、`num_chirps_per_frame = 768`。
- `COMPASS.md:34`：「chain 速度全展开 ±28.81 m/s」；`COMPASS.md:44/:228`：「DDM 把 28.77 报成 4.79」—— 文档已记录该缺口且内部自相矛盾（28.81 vs 28.77/4.79 并存）。
- 对照：`28.77 / 6 = 4.795 ≈ 4.79`，缺口恰为 num_subbands，坐实「漏乘子带因子」而非量纲或公式写错。

## 边界 / 反例
- 本条只坐实「28.77 vs 4.79 差 6 倍 = num_subbands」这个数值事实；「具体哪一行漏乘」是诊断推断，切片未记录 DDM 解调路径源码，未逐行取证。
- 28.81 vs 28.77 的 0.04 m/s 差异来自文档四舍五入/表述口径，与 6 倍缺口是两回事，勿混为一谈。
- 该因子只在 DDM/DDMA 这类「子带/发射通道复用」波形里出现；单发单收 FMCW 无此因子，判据别误套。

## 失败信号（未来命中即该想起本条）
- DDM 速度与链路公式差一个整数倍（num_subbands / num_tx），而非 1e3/1e6 量纲倍数。
- 文档里同一速度出现 28.81 / 28.77 / 4.79 多个版本，内部自相矛盾。
