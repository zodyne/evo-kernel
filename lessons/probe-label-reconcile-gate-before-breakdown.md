---
id: probe-label-reconcile-gate-before-breakdown
type: lesson
status: candidate
scope: global
domain: signal-processing
tags: [probe-script, reconcile-gate, self-check, analysis-methodology]
triggers:
  - "写探针/拆解脚本分析生产实现的逐点/逐帧行为"
  - "脚本复现的标签或中间量与生产实现有出入"
  - "分析脚本直接输出拆解结论，没有任何自检前置"
  - "对账率差一点没过门槛，犹豫要不要继续用结果（失败信号）"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fbb55-aff3-7aa0-937b-51eaddbeab92
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored]
---
# 探针脚本先过标签对账门槛再拆解：对账不过就直接声明"后续不可信"

## 主张

写探针/拆解脚本去分析生产实现（如 faf）的逐点行为时，**第一步先把自己复现的标签/中间量与生产实现逐点对账，并设硬通过率门槛（如 99%）**；对账不过就在输出里明说"后面的拆解不可信"并停手，而不是带病输出一份看似有结论的分析。自检门槛内建于脚本，不靠人记得去怀疑。

## 证据

faf_offline 的 reject_probe.py 跑 000034 窗（f1060..1095，36 帧）时输出：

```
标签对账: 2524/2565 = 98.40% 一致
对账未过 99%, 后面的拆解不可信
```

脚本自己拒绝继续产出逐点拆解，避免了基于 1.6% 标签错位得出的错误归因。

## 边界

- 门槛取值（99%）按分析对象的噪声水平定；标签本身含随机 tie-break 时 100% 不现实。
- 该模式只挡"复现与生产不一致"这一类错误；对账过了不代表后续拆解逻辑本身正确。
