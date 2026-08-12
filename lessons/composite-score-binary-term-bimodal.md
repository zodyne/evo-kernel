---
id: composite-score-binary-term-bimodal
type: lesson
status: candidate
scope: global
domain: algorithm-calibration
tags: [threshold, scoring, calibration, radar]
triggers:
  - "加权合成分数定阈值"
  - "阈值没有推导过程是拍脑袋的"
  - "分数分布双峰"
  - "二值特征混进连续加权分"
  - "KEEP 门限怎么来的"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:6f9c92c5
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---

**主张**：含二值子项的加权合成分数（如 `s = w1·a + w2·b + w3·(1−c)`，其中某项 ∈{0,1}）其分布必然双峰、峰间距等于该二值项权重；此时阈值落在两峰之间是**公式结构决定**的，不是标定出来的。追问「这个阈值怎么来的」要先分清：有物理量纲/分布依据的参数 vs 无量纲合成分数的人为设定值。

**为什么**：实测 `s_fa = 0.45·s_signal + 0.35·p + 0.20·(1−s_dop)`（p 二值，权重 0.35）：p=1 群体中位 0.599、p=0 群体中位远低于此，0.55 恰好卡在两峰之间当「持久性闸门」。报告只列参数未给推导，也没有任何脚本做过扫描/ROC——承认「人为设定」比假装有依据更诚实，也决定了换场景必须复验。

**边界**：双峰结构让阈值对中间区域不敏感（鲁棒），但也意味着微调阈值意义不大，要调就调权重或子项定义；核查时先画分数直方图按二值子项分群着色，一目了然。

**证据**：2026-07-27 ucm221 会话，用户追问 keep 阈值 0.55 来源，从公式结构与数据分布两侧查实。
