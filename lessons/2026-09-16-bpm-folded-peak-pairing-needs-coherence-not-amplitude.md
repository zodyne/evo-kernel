---
id: bpm-folded-peak-pairing-needs-coherence-not-amplitude
type: lesson
status: candidate
scope: global
domain: signal-processing
tags: [bpm, mimo, radar, pairing, coherence, doa]
triggers:
  - "BPM/MIMO 折叠产生的无序峰对配对判决"
  - "配对靠幅度失效（两峰高度几乎相同）"
  - "16 元虚拟阵相干度用于配对/DOA"
  - "雷达速度折叠峰对无法按幅度区分（失败信号）"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a4ee-6d56-777c-a410-3236022192ef
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [bpm-doppler-compensation-divide-by-tx]
---

# BPM 折叠峰对配对：幅度不可区分，只能靠 16 元虚拟阵相干度

## 主张

BPM 波形速度折叠产生的无序峰对，两个峰高度几乎相同，**配对判决不能靠幅度**；只能靠 16 元虚拟阵相干度（正确配对相干度 ≈1.0，错误配对 ≈0.0），把两发各自折叠出的峰正确配对到同一目标。

## 证据

- `[PASS] 无序峰对的两峰高度几乎相同 ⇒ 配对不能靠幅度，只能靠 16 元相干度`：`|X1|²/|X2|² = 0.9893（峰对 -9.89, +6.34 m/s）`；而相干度 `1.000 vs 0.001`。
- 交换两发后虚拟阵波束峰落在错误角度（相干度损失），正确配对才落回真值 az/el=12/9.6°。

## 边界

- 幅度比 0.9893 ≈ 1 是「幅度不可区分」的量化依据；若峰对幅度比显著偏离 1 才能谈幅度辅助。
- 相干度判决依赖虚拟阵孔径；单发/少 RX 场景可能退化。
