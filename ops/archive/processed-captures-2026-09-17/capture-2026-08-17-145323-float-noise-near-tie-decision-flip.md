---
id: capture-2026-08-17-145323-float-noise-near-tie-decision-flip
type: lesson
status: inbox
scope: global
domain: numeric-parity-testing
tags: [golden-diff, float-noise, argmax-tie, tolerance]
triggers:
  - "golden 差分个别单元翻转"
  - "argmax 平局浮点噪声选不同子带"
  - "检测点级对比差 1 个点"
  - "差分测试怎么写容差"
  - "浮点噪声翻转边际决策"
created: 2026-08-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:hermes-afm761-matlab-to-python-migration
last_verified: 2026-08-17
superseded_by: null
schema_version: 1
related: [bytes-exact-oracle-gate-for-pipeline-port, dual-impl-cross-check-tolerance-grid-anchored]
---

不同 FFT/数值库（MATLAB FFTW vs numpy pocketfft）间的 ~1e-13 相对浮点噪声，会在**近平局决策**处翻转离散输出——不是 bug，但会打破 bit-exact 差分。实测三类：①DDMA max_subband argmax 在低能量噪声单元翻转（256×32 单元中恰 1 个，(0,0) 能量接近的两个子带差 1e-8）；②DA 流 NMS 在 SNR 边际单元选相邻 az bin；③CFAR 阈值刚好被跨过。处置：①差分测试用"近平局感知"断言——允许 ≤N 个单元差异（N 极小），且每个差异单元必须落在低能量/近平局区（可验证：两候选值差 <1e-6 相对）；②点级对比升级为"帧级点数序列零差异"作端到端验收门禁（100 帧 × 两检测流实测 0 差异帧，比逐点 bit-exact 更稳健且更有工程意义）；③差异定位流程：逐级 golden 导出 → 二分定位差异出现的最小阶段 → 对该单元构造最小复现（如直接比较两个候选取值是否近平局）。教训：数值管线迁移的验收设计要**预期**噪声翻转的存在并提前写好容错断言，否则会花数小时追一个"不是 bug 的 bug"。
