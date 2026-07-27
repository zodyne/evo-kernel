---
id: stamp-baseline-before-review
type: lesson
status: validated
scope: global
domain: research-methodology
tags: [review, audit, baseline, staleness, parallel-work]
triggers:
  - "开始一轮代码/设计评审或审计"
  - "评审与实施并行推进（边审边改）"
  - "评审发现被回复「这个已经修了」"
  - "接手一份别人写的评审报告，不确定它基于哪个版本"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:e1d54d8c-33d7-425d-88e3-901189f4090c
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
评审/审计类工作**开工第一步是标注基线**：记下评审所依据的 commit sha 与时间戳，并在报告开头写明。

**为什么**：评审和实施常常并行——你在读的代码，作者正在改。等报告写完，一部分发现已经被独立关闭，另一部分则基于已经不存在的代码。没有基线标注就无法区分"这条发现过期了"和"这条被忽略了"，双方只能靠记忆争论。实例：Evo-Kernel 一轮 Claude 评审基于 P3 前的快照，其中 R2 项在报告产出时已被实施关闭。

**做法**：开工 `git rev-parse --short HEAD` 记下基线；报告头部写「基线：<sha> @ <时间>」；交付时如果基线已落后，明确列出"以下发现需按新版本复核"，而不是默认全部有效。

**边界**：针对与实施并行的评审。事后审计（代码已冻结）不受此困扰，但标注基线成本近零，照做无害。
关联 [[design-review-cross-check-implementation]]：那条讲评审须核对实现现状，本条讲现状本身在动、必须钉住时间点。
