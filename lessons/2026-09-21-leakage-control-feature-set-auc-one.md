---
id: leakage-control-feature-set-auc-one
type: lesson
status: candidate
scope: global
domain: machine-learning
tags: [leakage, feature-engineering, auc, control-experiment, threshold-learning, radar]
triggers:
  - "用带 GT 标签的数据训练/评估门限或分类器"
  - "特征里含与标注口径同源的量（距离门、多普勒、SNR 门、标签生成用的中间量）"
  - "学习模型的 AUC 顶到 0.99+ 或明显超过手工判据基线，怀疑泄漏（失败信号）"
  - "设计『学习阈值 vs 手工判据』的对照实验，要说清增益来源"
  - "写实验报告准备声称「学习模型超过现有规则」"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0bcf1-4733-7265-ada1-fb36116f6be1
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [calibration-set-not-validation-set, recalibrate-thresholds-before-comparing-sets]
---

# 学习门限实验必须带「含泄漏特征」对照组：AUC 1.0000 只能来自泄漏

## 主张

做"学习门限 / 学习判据"实验时，固定跑一组"含泄漏特征"的对照——把 距离门 / |多普勒| 这类与标注口径同源的量放进特征：本例 000028 含泄漏 AUC 1.0000 / 召回 99.70%，而无泄漏快照内对照 AUC 0.9558 / 97.00%。AUC 顶到 1.0 只可能来自泄漏；没有这组对照，"学习模型 AUC 0.97 > 现有判据 0.9554"的结论无法排除泄漏解释。

## 为什么

现有判据（s = p1·cos(γ−γ₀) 一类）本身就在 0.95+ 的量级，AUC 上升几个千分点很容易被当成真实增益。当特征里混入标签生成链路上用到的量（距离门、多普勒这类门限/采样口径）时，模型可以直接复现标注规则，AUC 跳到 1.0。把已知的泄漏特征单列一组当"正对照"，是先证伪上限：含泄漏组也上不去，说明这些量没泄漏；上去了，则在真实模型里剔除它们并重新解释增益。

## 证据（session 01a0bcf1，suc221-pointcloud-2.0）

- 实验协议（本会话落地 `docs/design_bf/learned_threshold_study.py`）：`[A] 同场景学习（前半训练 → 后半评测）· 放行率匹配到 0.1714 -- 000028（正样本 3911 / 1,905,881 点） 基：s（现行判据） AUC 0.9554 召回 96.80%`。
- 泄漏对照：`[D] 泄漏对照（把 距离门 / |多普勒| 放进特征） 000028 含泄漏 AUC 1.0000 召回 99.70% ← 对照（快照内）：AUC 0.9558 召回 97.00%`。
- 结论被写进 `docs/design_bf/LEARNED_THRESHOLD.md`（同场景学习、放行率匹配、无标签在线的边界几节）。

## 边界 / 反例

- 切片未展开 GT 标签的生成细节；"距离门 / |多普勒| 与标签同源"是实验设计者的判定（实验即名为"泄漏对照"），本条引用的是它对 AUC 的量级影响，不复述标签构造规则。
- 对照组不改进模型，作用是否证上限；若含泄漏组 AUC 也只有 0.96，则这两个量不构成泄漏，需另找泄漏源。
- 特征泄漏与"标定集当验证集"（`calibration-set-not-validation-set`）是两类泄漏，都要防：前者在特征层，后者在数据划分层。

## 失败信号（未来命中即该想起本条）

- 学习/调参实验报告 AUC 0.99+，特征清单里却有直接参与标签定义的量。
- 拿"学习模型 AUC 0.97 > 现判据"当结论，但没有任何对照说明标签可分性的上限。
