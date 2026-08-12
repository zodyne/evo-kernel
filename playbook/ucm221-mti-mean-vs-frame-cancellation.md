---
id: ucm221-mti-mean-vs-frame-cancellation
type: bullet
status: validated
scope: project:ucm221
domain: radar-signal
tags: [ucm221, mti, 静杂波, 对消, 机理, 实测]
triggers:
  - "MTI 对消参考选型：滑窗均值(mean) vs 相邻帧(frame)"
  - "mean 与 frame 对消深度不同但检出率相同，想解释机理"
  - "担心杂波图含目标自身导致慢目标自对消"
  - "对消后噪底变化异常，要核对理论值"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-03-08-22-58-089-gjhg
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: [ucm221-static-clutter-notch-beats-mti]
---
随机帧间相位抖动模型下，mean 对消与 frame 对消的检出能力等价（UCM221 静止地面数据实测闭环）。

**机理**：mean 对消深度优 4.3dB（实测 +3.8dB），但被噪底差异抵消——mean 噪底 −1.25dB vs frame +3.0dB，两者均与理论 σ²(1−1/N)/2σ² 精确吻合；对消后杂波残差 SNR 分布相同（中位 +6.2/+5.7dB），CFAR 自适应门限下检出率相同。但检测集合是两套近独立的随机泄漏子集（Jaccard 仅 0.28）。

**选型差异仅三条**：
1. frame 跳过 frame0，损失 25% 时间覆盖；
2. mean 噪底低 4.26dB，对幸存弱动目标更灵敏；
3. mean 杂波图含目标自身，有慢目标自对消风险（4 帧窗口）；frame 自对消窗口仅 1 帧。

**边界**：等价结论依赖"随机帧间相位抖动"前提；若相干性改善（抖动 σ 下降），对消深度差异可能不再被噪底抵消。
