---
id: cfar-cross-lib-equivalence-baseline-first
type: lesson
status: candidate
scope: global
domain: radar-signal
tags: [cfar, cross-validation, equivalence, regression-assertion, detected, gocfar]
triggers:
  - "跨 1D/2D CFAR 库做对比（detected vs gocfar）"
  - "两个实现的差异无法归因，不知道是算法不同还是参数不同"
  - "detected(ColumnsOnly + GreaterMean) 与 gocfar(GreatestOf) 是否应逐点完全相等"
  - "用差集定位 bug（差集 700 条 100% 是 col>=512）"
  - "默认 Intersection vs 1D 距离扫描：检测统计量和扫描维度同时不同（反例）"
created: 2026-08-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-14-04-40-27-716-mbt5
last_verified: 2026-08-14
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored, detected-limits-signed-column-clips-half-hits]
---

# 主张

跨 1D/2D CFAR 库做对比时，**先建等价基准再谈差异**：`detected`（ColumnsOnly + GreaterMean）与 `gocfar`（GreatestOf）在同套窗口参数下应逐点完全相等。

这条等式既是回归断言，也是排查工具——两边不等时**差集本身就指向 bug**。

# 证据

SUC221 里差集 700 条 100% 是 `col>=512`，直接定位到 limits 裁剪（见 `detected-limits-signed-column-clips-half-hits`）。

# 反例

默认 `Intersection` vs 1D 距离扫描：检测统计量和扫描维度同时不同，任何差异都无法归因——不满足「先建等价基准」的前提，不能拿来做对拍。
