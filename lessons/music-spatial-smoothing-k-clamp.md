---
id: music-spatial-smoothing-k-clamp
type: lesson
status: candidate
scope: project:ucm221
domain: radar-doa
tags: [music, doa, spatial-smoothing, coherent-sources, parameter-clamp, ucm221, radar]
triggers:
  - "给 MUSIC/子空间类 DOA 算法配空间平滑档位"
  - "空间平滑后仍按全阵列设默认信源数 K，结果异常（失败信号）"
  - "评审/实现 MUSIC 参数表，检查 K 与平滑档位的组合合法性"
  - "相干源场景 MUSIC 谱峰数不对或噪声子空间维数被压没"
created: 2026-08-11
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:pi-design-review.t-002
last_verified: 2026-08-11
superseded_by: null
schema_version: 1
---
# 空间平滑 MUSIC：K 上限是 L−1 不是 M−1，默认 K 必须按 K_eff=max(1,min(K_ui,L−1)) 钳制

## 主张

前向空间平滑 MUSIC 中，平滑档位 s 使有效子阵长缩为 L = M − s（子阵数 s+1），可分辨（相干）信源数上限随之降为 K ≤ L−1。按全阵列定的默认 K（如 M=8 时 K=6）在深平滑档位（如 s=3 → L−1=4）直接越界，会把噪声子空间维数压没。参数表/默认值必须钳制：`K_eff = max(1, min(K_ui, L−1))`，且对外应体现 K_eff 而非原始 K_ui。

## 证据

pi-design-review.t-002 评审 UCM221 测角方案时，round-0 blocking finding **B1** 即「MUSIC 默认参数 K=6 vs L−1=4 冲突」；round-1 修复方案（§2.3 新增平滑语义与 K 钳制）经 python 数值复核逐档验证：

```
s=0: L=8, 子阵数=1(应=s+1=1), K_eff=6, 噪声子空间维数=2
s=3: L=5, 子阵数=4(应=s+1=4), K_eff=4, 噪声子空间维数=1
s=5: L=3, 子阵数=6(应=s+1=6), K_eff=2, ...
```

噪声子空间维数 = L − K_eff，钳制后各档均 ≥1，修复成立（该轮 verdict: approve）。

## 反例/边界

- 非相干源、不做空间平滑的场景不受此限（K ≤ M−1 即可）。
- 钳制是静默降能力：深平滑档位下可分辨源数被压到 1~2，产品侧若承诺更高源数需在指标层面同步降口径，不能只改算法参数。
