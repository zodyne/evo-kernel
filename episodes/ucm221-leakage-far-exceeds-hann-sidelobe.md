---
id: ucm221-leakage-far-exceeds-hann-sidelobe
type: episode
status: candidate
scope: project:ucm221
domain: radar-signal
tags: [泄漏, hann窗, 距离谱, 暗室数据]
triggers:
  - "UCM221 分析 bin0 平坦泄漏渗入 bin3 的机理"
  - "用 Hann 窗副瓣理论预测泄漏污染量级"
  - "论证大角度测角发散的机制二（泄漏污染）"
  - "实测泄漏比理论窗函数预测差几十 dB（失败信号）"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:583c96aa-69cd-41b3-926b-4f72d4d7c7f5
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [episode-ucm221-uneven-array-doa]
---

UCM221 实验 B（exp_b_leakage.py）实测：bin0→bin3 的泄漏污染**远超 Hann 窗副瓣理论预测**，泄漏不能按"纯 DC 音 + Hann 副瓣衰减"建模。

硬数据（az_-45 采集点）：bin0/bin3 = -5.0dB，实测污染 -22.6dB，Hann 预测 -83.3dB，**实测比理论高 ~60dB**——泄漏谱含杂散分量，不是纯 DC 音按副瓣衰减能解释的。

含义：凡用窗函数理论量级去估算/豁免泄漏污染的论证都站不住，必须实测（实验 C 的窗尾扣除/投影扣除即为此设计）。
