---
id: bpm-vmax-folding-window-lambda-over-2tc
type: lesson
status: candidate
scope: global
domain: radar
tags: [bpm, mimo, velocity, vmax, folding, doppler, ambiguity, hadamard]
triggers:
  - "核对/验证 BPM-MIMO（慢时间 Hadamard 编码）波形的最大不模糊速度或折叠窗口宽度"
  - "文献里同一 BPM 波形出现 λ/(8Tc) 与 λ/(4Tc) 两种 v_max，不知道该信哪个"
  - "用 fold(v, v_max) 做速度折叠核验，结果对不上（失败信号：折叠后误差接近整个窗口宽）"
  - "审查 BPM 速度估计代码，怀疑折叠窗口取错（用了 v_max 而非 2·v_max）"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a521-3d9b-777c-a410-32526976d57d
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [bpm-folded-peak-pairing-needs-coherence-not-amplitude, ddm-max-radial-vel-missing-subband-factor]
---

# BPM 速度折叠窗口是 2·v_max = λ/(2Tc)，且「v_max」有 λ/(8Tc) / λ/(4Tc) 两种口径

## 主张
BPM-MIMO（2 发，慢时间 Hadamard 编码）的速度折叠/解模糊窗口宽是 **2·v_max = λ/(2Tc)**，不是 v_max = λ/(4Tc)。且文献里「BPM 的 v_max」本身有**两种口径**：λ/(8Tc) 指频带分区、λ/(4Tc) 指假设检验，两者都"对"——核验前必须先确定自己用的是哪种口径，否则会用错折叠窗口。

## 为什么
用错窗口会把正确的速度估计判成"对不上"（或反过来把错峰判成对）。本例 77 GHz、Nc=128、Tc=60 µs 下 λ/(2Tc)=32.445 m/s，恰好等于 2·v_max（v_max=λ/(4Tc)=16.22）。若误拿 v_max 当折叠窗口宽，正确结果会被 fold 到错误位置，误差量级接近整个窗口宽，看起来像"仿真错了"实则是核验口径错。

## 边界 / 反例
- 与 `ddm-max-radial-vel-missing-subband-factor` 不同：那条是 DDMA 漏乘子带/发射通道数导致差整数倍；本条是 BPM 两种 v_max 口径 + 折叠窗口应取 2·v_max，不是差整数倍而是"窗口宽减半"。
- 与 `bpm-folded-peak-pairing-needs-coherence-not-amplitude` 是前置关系：先把折叠窗口定对（2·v_max），再谈两发无序峰对的配对判决。窗口定对只解决"把速度折回主值区间"，不解决"哪个峰属哪一发"。
- 折叠窗口 ≠ 频带分区口径的 v_max（λ/(8Tc)）；混淆这两者会把窗口宽再差一倍。

## 证据（2026-09-15 会话命令对照）
- README §6b 文档原句（grep 命中）：「术语坑：文献里『BPM 的 v_max = λ/(8Tc)』与『λ/(4Tc)』都对，分别指频带分区与假设检验两种口径」。
- a2.py 命令输出数值确认：`v_max=16.222536 P=2v_max=32.445071 lam/(2Tc)=32.445071`，即 2·v_max = λ/(2Tc) 逐位对上。
- a2c.py 核验脚本自述判据：「正确的检验：v_meas 是否 = fold(v_true, 2v_max)（窗口宽 2v_max = λ/(2Tc)）」。
