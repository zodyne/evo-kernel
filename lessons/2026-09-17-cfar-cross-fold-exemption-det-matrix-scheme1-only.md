---
id: cfar-cross-fold-exemption-det-matrix-scheme1-only
type: fact
status: candidate
scope: project:algommw
domain: radar-dsp
tags: [algommw, cfar, peak-grouping, same-fold, ddma]
triggers:
  - "给 algommw 换/改 peak_group_scheme，拿不准各方案跨 fold 行为差异"
  - "DDMA 雷达 CFAR 峰值分组要不要跨 fold 合并/豁免"
  - "algommw 对拍发现方案 1 与其它 peak_group 方案点数系统差（失败信号）"
  - "在 cfar.c 里找 same_fold_only / prvPeakSurvives 的适用范围"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae37-a909-77c1-a593-51c0d61c185c
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [algommw-profile-single-config-source]
---

algommw C 核 CFAR 的跨 fold 豁免只做在方案 1：`core/src/dpu/cfar/cfar.c:431` 注释明说"参考流 same_fold_only 的跨 fold 豁免只做在方案 1(prvPeakSurvives,det_matrix)"——即 peak_group 方案 1 与其它方案的跨 fold 行为不等价，这是源码注释自认的已知实现边界。

**为什么**：DDMA 场景下切换 `peak_group_scheme` 时，跨 fold 豁免行为跟着方案走；若默认各方案语义一致，对拍/golden 比对会出现方案间系统差，容易误判成某方案有 bug 或 golden 有错。

**边界**：豁免的具体语义（豁免什么、为何需要）切片未展开；grep 输出被截断，`prvIsNeighbour/prvDist2/prvClusterStats/eClusterProcess` 的命中行未取得；只断言注释所述事实，不推断豁免机制细节。

**证据**：slice 命令↔结果第 7 条：`grep -n "prvPeakSurvives\|prvIsNeighbour\|prvDist2\|prvClusterStats\|eClusterProcess" core/src/dpu/cfar/cfar.c core/sr…` ↳ `core/src/dpu/cfar/cfar.c:431: * 参考流 same_fold_only 的跨 fold 豁免只做在方案 1(prvPeakSurvives,det_matrix)。`
