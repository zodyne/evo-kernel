---
id: repeated-tuning-deadlock-switch-to-literature
type: lesson
status: candidate
scope: global
domain: research-method
tags: [research-method, information-retrieval, tuning, literature, evaluation-design]
triggers:
  - "同一问题反复调参仍无结论（第二次调参仍没定论）"
  - "长 prompt 过度注入 / 检索阈值调不动，想继续改公式"
  - "只拿 4 个用例判两种方案优劣"
  - "怀疑实现方式、却只在本地试验里找答案（失败信号）"
  - "想用『再调一版参数』解决框架层面的问题"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-09-22-17-661-ib1w
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: []
---

# 同一问题反复调参仍无结论时应停止本地迭代、改去查原始文献

## 主张

同一问题反复调参仍无结论时应停止本地迭代、改去查原始文献 —— 因为「我的框架本身是错的」这件事无法靠同一框架内的实验发现。

## 实例

为治「长 prompt 过度注入」，我连加 v1（分母下限）/v2（idf）/v3（叠加）/v4（最少命中 2 个 term），并跑了 bench（4 用例）+ 回放（559 查询）两轮评测，结论始终摇摆、每次都被自己的数据反驳。一次文献查证直接推翻框架：

① cover=命中/|短语| 是 coordination level matching（Cooper 1987），经典但已知「把所有词当同等重要、忽略 term specificity」；② BM25 的查询侧**不做长度归一**（Manning《IR》ch11：Length normalization of the query is unnecessary），长度归一只作用于文档/字段侧；③ 故「按字段长度归一 + 跨查询固定绝对阈值 0.25」使分数对查询长度单调不减 → 长查询更易过阈；④ 查不到「长查询导致假阳性上升」的 IR 一般结论（TREC 长 topic 常 MAP 更高）⇒ 该现象是**我实现方式的产物**，我却把它当成「长 prompt 的固有难题」；⑤ 标准解法是查询内相对排序/top-k/分数归一化（Montague & Aslam 2001），不是继续调公式；⑥ 方法学：TREC 用 50 topics 并做显著性检验，我拿 4 个用例判优劣在专业标准下不成立。

## 判据

同一问题第二次调参仍无定论 → 转查文献（教科书章节 + 原始论文 + DOI），不要再动参数。
