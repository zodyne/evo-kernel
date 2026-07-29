---
id: recall-failure-empty-vs-noise-taxonomy
type: lesson
status: validated
scope: global
domain: retrieval
tags: [recall, evaluation, failure-taxonomy, noise, precision]
triggers:
  - "分析检索/召回基准的失败用例"
  - "召回不达标，要决定先扩召回还是先提精度"
  - "评测只报一个通过率，看不出失败形态（失败信号）"
  - "召回到了错误条目，agent 被带偏方向"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:8e6bf649-a112-4ed7-a3bb-5391e23931a0
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [injection-precision-must-split-recall-vs-adoption, rerank-channel-design]
---

# 召回失败分两类：空命中是"够不着"，误召回是"引错路"——后者更糟，修法相反

## 主张

评估检索/召回质量时把失败用例分成两种形态再开处方：**空命中**（目标条目根本没进候选，召回层够不着）与**误召回**（召回了错误条目）。误召回比空命中危害更大——空命中只是没帮忙，误召回抢占有限注入位并把 agent 引向错误结论；且两者修法相反（扩召回 vs 提精度/加治理权重），混在一个通过率里会开错药。

## 为什么

evo-kernel 检索基准首次基线（2026-07-28，scan 后端，60 条库）把失败逐例分类后，形态立刻清晰：

- 空命中 3 例：T-timeout、T-heredoc、T-cfar——目标条目与查询措辞零重叠，召回层够不着；
- 误召回 1 例：T-arxiv 期望 arxiv-api-rate-limit，实得 arxiv-download-proxy-truncation——噪声条目抢位，比空命中更糟。

整体 transfer 阶段仅 25%（换措辞描述同一问题，四次只有一次召回正确条目）。若只看通过率会笼统"加召回"，但那会把误召回一并放大；分类后才定位到正确机制（cover 按短语自身长度归一导致的评分倾斜）。

## 反例/边界

- 两类不是互斥穷尽：还有"目标在候选但排序沉底"（归 rerank/排序层，不归召回层），分析时单列。
- 小样本下单个用例的分类可能因措辞改动翻转， taxonomy 用于定向而非精确计数。
- 注入位无限的系统里误召回代价下降，但单 agent 上下文预算总是有限，本条在 agent 记忆场景普遍成立。

## 证据

- 命令：`node test/retrieval-bench/bench.js --json` 失败用例清单输出"空命中（召回层够不着）：T-timeout/T-heredoc/T-cfar；召回了错条目（噪声型失败，比空命中更糟）：T-arxiv → arxiv-download-proxy-truncation"；基线记录于 test/retrieval-bench/BASELINE.md。
