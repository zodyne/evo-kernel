---
id: eval-negative-only-data-hides-overfiltering
type: lesson
status: candidate
scope: global
domain: methodology
tags: [evaluation, validation-data, false-alarm-filter, degenerate-baseline, ucm221]
triggers:
  - "手里只有纯负样本数据（净空/全是虚警），要评估过滤器/分类器效果"
  - "评估指标看起来满分，怀疑是退化模型也能拿满分（失败信号）"
  - "报告 KEEP 率/抑制率很好看，但没有任何已知真目标穿过管道"
  - "设计过滤器的验证方案，选评估数据集"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:da720f38
last_verified: 2026-07-31
superseded_by: null
schema_version: 1
related: [calibration-set-not-validation-set, recalibrate-thresholds-before-comparing-sets]
---

# 纯负样本数据评估过滤器：结构上只能度量漏杀，退化过滤器也得满分

**主张**：只用「认定全部点都是虚警」的数据（如净空飞行数据）标定和评估过滤器，这类数据**结构上无法度量误杀**——任何被砍掉的点都算"砍对了"，一个把所有点全判 REJECT 的退化过滤器也能拿满分。评估数据必须含已知真目标（GT 航迹、暗室真值、人工确认目标），否则得出的"泛化能力强"结论要撤回。

**为什么（UCM221 实例）**：faf 初版只用净空数据评估，得出"KEEP 率 10–14%、泛化能力强"——它只证明了抑制强度稳定。改用 legacy 长命航迹当 GT 后立刻暴露三处设计缺陷（persist 硬分格、综合分数结构性上界 0.45 < 门槛、dc 误杀近距真目标），初版结论全部推翻重写。

**边界**：纯负样本数据仍有用途——度量抑制率上限与稳定性、做 golden 回归；但不能作为"过滤有效"的证据。与 calibration-set-not-validation-set 互补：那条讲标定集不能当验证集，本条讲负样本集不能证正例存活。

**证据**：session da720f38，false_alarm_filter_report.pdf 重写新增 §1.2 验证方法论与 §9 三处缺陷（各带实测证据）。
