---
id: two-state-candidate-decision-not-tracking
type: lesson
status: candidate
scope: global
domain: radar-signal
tags: [候选判决, 两态跳变, 跟踪器, argmax, 水面回波]
triggers:
  - "单帧输出在两个稳定值（如水面/结构）之间跳变，第一反应想上 α-β/门控/中值滤波平滑"
  - "多候选按最大 SNR / argmax 每帧直接输出，事后统计发现稳定锁在错误候选（失败信号）"
  - "跟踪器输出看起来很平稳（切换/天 低），但目标身份是错的（失败信号）"
  - "两候选幅度接近，单帧选择像抛硬币，需要判断该建成跟踪问题还是概率判决"
  - "想把『抖动脉冲』交给跟踪滤波解决前，要量化平滑到底能挽回多少身份正确率"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bdef-64b5-738d-af4a-290ada962882
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [multi-seed-identical-readout-suspect-seed-not-wired, track-gap-attribution-viewport-gate-vs-filter]
---

# 双态候选跳变先做身份概率判决，α-β/门控平滑救不回来

## 主张

上游每帧在两候选间做硬选择（「取最大 SNR/argmax」直接输出）时，若候选近似双态（如 WTR10 的水面/结构），下游再加 α-β + 门控平滑也无法纠正身份误选：实测门控 α-β 落在正确候选（水面）的比例只有 0.3%，与基线直通 0.0% 几乎相同；正确做法是把问题建成候选身份的概率判决（用散斑统计/相干性等），跟踪只是判决之后的从属环节。

## 证据（session 01a0bdef，wtr10/dsp_research 仿真脚本）

- 上游标定：两态占比约 30%（水面 29.6%，报告实测 29%）；「每帧取 SNR 最大者直接输出」落在水面 0.4%、RMS 7.716 m、切换/天 888。
- 平滑极限（无净化两态输入）：基线直通落在水面 0.0%、RMS 7.730 m、切换/天 1；加门控 α-β（无 SNR 判据）后落在水面仅 0.3%。另一组参数的 argmax 上游水面占比 14.4%、基线 RMS 7.153 m、切换/天 21933。
- 会话收尾结论（末条 assistant）：「这是概率判决（candidate identity decision），不是跟踪。跟踪（α-β 平滑轨迹）只是判决之后的从属环节。」

## 边界 / 反例

- 两条失败信号性质不同：argmax 版切换/天数千、抖动明显；门控 α-β 版「切换/天 1」看起来很平稳，但那是锁死在错误候选上的假稳定——平稳不等于判对。
- 以上均为按报告实测统计标定的合成两态模型（散斑统计 + 固件定义）仿真，不是外场复核；真实场景的判决统计量（散斑/相干性）需另行验证。
- 若上游候选本身可分（不是两态近似），跟踪平滑仍是正常手段；本条只针对「单帧判决本身错误、跟踪被当成长矛」的情形。
