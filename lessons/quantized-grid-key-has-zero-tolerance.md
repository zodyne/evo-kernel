---
id: quantized-grid-key-has-zero-tolerance
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: signal-processing
tags: [quantization, grid-key, matching, persistence, off-by-one-cell]
triggers:
  - "用量化/取整后的网格 key（体素、分格）做跨帧/跨集合点匹配"
  - "名为 tolerance 的参数实际匹配率为零或极低（失败信号）"
  - "连续出现的真实目标跨帧持久性恒为 0"
  - "匹配容差改了没效果，命中率远低于预期"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:da720f38
last_verified: 2026-07-31
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored]
---

# 量化网格 key 做匹配 = 容差为零：跨格邻居永远失配

**主张**：把连续坐标量化成网格 key（如 `round(angle/3°)` 分格）再按 key 相等做匹配，**名义上的容差参数在格边界处实际为零**——目标抖动 0.98° 就换格，前后帧永不同 key。修法：匹配时搜索相邻 27 格（3×3×3）或改用连续距离判定，不要用量化 key 的相等当"同点"。

**为什么（UCM221 实例）**：faf 的跨帧持久性用体素 key 匹配，`persist_tol` 名为容差、实为硬分格。实测 ID1 目标连续检出 5 帧但 persist 帧帧为 0（角度抖 0.98° 换格），全局精确命中率仅 6.4%——持久性特征整体失效，进而把综合分数压出结构性上界（0.45 < keep 门槛 0.4597），"dop=0 且不持久"的 13,432 个点 KEEP 恰为 0。

**边界**：网格 key 适合先做粗筛（分桶加速），但终判必须落到连续量；量化步长 ≥ 2× 真实抖动时命中率才像样，步长接近抖动量级必然崩。

**证据**：session da720f38，report §9 缺陷一/二及 persist 帧帧为 0 的逐帧记录。
