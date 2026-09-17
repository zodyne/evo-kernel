---
id: recheck-literature-after-implementing-literature-fix
type: lesson
status: candidate
scope: global
domain: research-method
tags: [research-method, information-retrieval, literature, threshold, abstention]
triggers:
  - "按文献结论实施修复后仍然出错，想在同一方案内继续调"
  - "『零模型显著性』/ DFR / 换皮公式是否已有等价文献"
  - "检索分数归一化该服务于排序还是『是否注入』"
  - "本地测试反复证伪假设，但框架本身没被证伪（失败信号）"
  - "固定绝对阈值同时承担排序与是否注入两职"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-14-09-32-46-175-6v0v
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: []
---

# 按文献结论实施后若再出错，应再次查文献，而不是继续本地改

## 主张

论证不是一次搜索：按文献结论实施后若再出错，应**再次查文献**，而不是在同一方案内继续本地分析/修改/测试。

## 实例

为治「长 prompt 过度注入」做了四轮本地迭代（v1 分母下限 / v2 idf / v3 叠加 / v4 最少命中数）+ 两轮评测（bench 4 用例 + 回放 559 查询），结论始终摇摆被自己的数据反复反驳。第一次查证推翻框架：真缺陷是「按字段长度归一 + 跨查询固定绝对阈值 ⇒ 分数对查询长度单调不减」，标准解法是查询内相对排序/归一化，不是在公式上加权。我随即凭直觉提出「零模型显著性」并准备实施，**第二次查证再次推翻**：

① 该方向就是 DFR（Amati & van Rijsbergen 2002），且有 2025 论文证明 TF-ICF ≈ Fisher 精确检验 p 值、超几何 ≈ TF-IDF ⇒ **换皮，边际收益近零**；② cover=命中/|短语| 就是 Broder 的 containment，已知不对称、非度量、分母敏感、不宜单独作阈值判据 ⇒ 缺的是长度归一化（Singhal 1996），不是新公式；③「零注入」在 IR 里无标准，对应机制是 abstention/选择性分类（Chow 1970；Geifman & El-Yaniv）与 Query Performance Prediction，其阈值应落**校准后的 P(relevance)**（决策论 IR / PRP）——而分数归一化只服务**融合**。

根因：固定绝对阈值同时承担「排序」与「是否注入」两职，而文献证明两者机制不同。

## 规则

①同一问题第二次调参无定论 → 查文献；②按文献实施后再出错 → **再查一次**，第二次错误常说明框架还有一层没拆开；③本地测试只能证伪框架内的假设，证伪不了框架本身。
