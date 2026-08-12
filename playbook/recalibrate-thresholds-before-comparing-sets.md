---
id: recalibrate-thresholds-before-comparing-sets
type: bullet
status: validated
scope: global
domain: methodology
tags:
- algorithm-change
- threshold-recalibration
- iou
- ab-evaluation
- ucm221
triggers:
- 改了算法/特征权重后，沿用旧阈值比较新旧输出集合
- 变更评估指标暴跌（KEEP 数/召回/IoU），要判断是真退化还是阈值失配
- 拿 IoU/重合度当'变差没有'的判据（失败信号：IoU 只说变了多少）
- 评估一个占权重较大的特征被改/被抽掉的影响
created: 2026-08-12
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: 人工（整理 inbox/capture-2026-07-28-04-00-17-843-ewwj.md）
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related: []
---
# 算法变更的代价评估：先重标定再比集合，再用独立特征判"变差没有"

**主张**：算法变更（尤其改动占分权重的特征）后评估代价，三步缺一不可：①**先重标定阈值再比集合**——沿用旧阈值测到的集合差异是阈值失配而非信息损失；②重标后指标才是真实代价；③**IoU/重合度只说"变了多少"，不说"变差没有"**——要用没参与该特征计算的独立量做成分对比，判定是重心转移还是退化。

**为什么（UCM221 实例）**：persist 从 ±1 帧改成仅前帧（消除 1 帧延迟）。沿用旧 keep_score 测得 KEEP 暴跌 38.8%、IoU 61%——但 persist 占 0.35 权重，抽掉后整条 score 分布下移，旧阈值当然切掉更多；这测的是阈值失配。按同分位点把 keep_score 从 0.55 重标到 0.4597（KEEP 数量对齐）后，IoU 才是真实代价 47%。进一步用未参与 persist 计算的 SNR 与其他独立特征做成分对比：换进来的点 SNR 更高、hpr 更低——判定为**重心转移而非退化**。

**反例/边界**：变更不涉及打分/阈值链路（纯格式/性能改动）时无需重标定；重标定必须用"同分位点/同数量"这类中性锚点，不能用结果指标本身当锚（那是循环论证）。

**证据**：capture-2026-07-28-04-00-17-843-ewwj（UCM221 persist 变更评估全流程实测数据如上）。
