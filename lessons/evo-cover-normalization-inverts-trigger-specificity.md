---
id: evo-cover-normalization-inverts-trigger-specificity
type: lesson
status: candidate
scope: project:evo-kernel
domain: retrieval
tags: [recall, cover-score, normalization, triggers, inverted-incentive]
triggers:
  - "改 evo recall 的 cover/relevance 打分公式"
  - "具体 trigger 的条目召不回、泛 trigger 噪声条目反而命中（失败信号）"
  - "命中词更多的条目得分低于命中更少的"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:8e6bf649
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
---
# cover = hits/|phrase| 按短语自身长度归一，激励是反的：trigger 越具体越难召回

**主张**：evo recall 的 triggers 通道 `cover = hits / |phrase|` 按短语自身长度归一，导致长而具体的 trigger 天然得分低——实测目标条目命中 2 词（trigger 14 term → 0.143，被 0.25 阈值滤掉）输给噪声条目命中 1 词（trigger 4 bigram → 0.250 通过）。**命中更多的输给命中更少的。**

**为什么**：按短语自身长度归一对长短语是双重惩罚（命中概率低 × 分母大）。同一缺陷当年已在 tag 通道用"取并集"修过，triggers 通道被漏下——同类打分公式改动要检查所有通道。另外注意卡住召回的是**绝对阈值**不是排序：v1/v2/v3 三个变体只改相对次序，transfer 全部原地不动。

**边界**：这是打分机制分析，修复方案（分母下限/idf/并集）当时均未切默认（见 eval-bench-replay-disagree-trust-replay）；后续改动需先补 bench 长查询用例再仲裁。

**证据**：session 8e6bf649，T-gitadd 实例逐项核对；BASELINE.md 第二条记录有完整变体表与阈值扫描。
