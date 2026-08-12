---
id: score-direction-auc-and-effective-weight
type: lesson
status: candidate
scope: global
domain: scoring-systems
tags: [auc, score-sign, weight, variance, doppler, faf]
triggers:
  - "多特征加权打分上线或调权前"
  - "某打分项 AUC < 0.5（失败信号：方向反了）"
  - "名义权重小的特征主导了总分方差"
  - "二值特征与连续特征混进同一加权和"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:b0e19d24
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
---
# 打分项上线前先验 AUC 方向；实际话语权是 w·σ 不是 w

**主张**：多特征加权打分，每个分项先用标注数据验可分性方向——**AUC < 0.5 即符号反了**；评估各分项实际影响力看 **w·σ（权重×标准差）**，不是名义权重 w。

**为什么**：faf 实例两个实证——① `dop_score` 量的是"偏离帧内多普勒主峰的程度"，主峰即静止杂波，运动真目标必然偏离，公式却记为正分，等于给杂波加分：AUC=0.113（正样本均值 0.020/负样本 0.551），仅反号 d′ 从 1.69→3.41，而它 KS 0.768 本是判别力第一的特征。设计文档注意到了后果但归类错（"分数上界"而非方向错误）。② `persist` 名义权重最小（0.35）却因二值（σ=0.42）占总分方差 60.5%、中性化翻转 18.5% 判定；名义最大的 signal（0.45）只占 22.7%。

**边界**：AUC 验方向需要可信标注（本例用 GT 航迹对账点级标签）；权重考古发现仓库无推导记录时更要先验方向再谈调权。

**证据**：session b0e19d24 权重报告（逻辑回归/Fisher/网格搜索复做，全量对账 100.000%）。
