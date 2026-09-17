---
id: matlab-find-and-colon-are-column-major
type: fact
status: validated
scope: global
domain: matlab-python-migration
tags: [matlab, numpy, indexing, reshape]
triggers:
  - "MATLAB find 线性索引移植"
  - "np.nonzero()[0] 拿到行索引不是线性索引"
  - "AZ(:) 展平顺序 / 列主序 reshape order=F"
  - "移植 MATLAB 索引/reshape 用法"
  - "索引域混用导致 IndexError（失败信号：snr 排序索引值 234 而候选仅 41 个）"
created: 2026-08-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-17-145321-matlab-indexing-flatten-semantics
last_verified: 2026-08-17
superseded_by: null
schema_version: 1
related: [dual-impl-cross-check-tolerance-grid-anchored, numpy-where-2d-mask-1d-values-needs-ravel]
---

# 主张

MATLAB 索引用法的两个高频移植坑：

1. `find(A)` 返回**列主序线性索引**，而 numpy `np.nonzero(A)[0]` 对 2-D 数组返回**行索引**——在「对 mask 内元素按分数排序取前 K」类逻辑（NMS、每 range 目标数限制）里混用会得到错误的索引域。
2. MATLAB `A(:)` / `reshape(vec, N, M)` 是**列主序**（第一维最快），numpy 默认 C 序（最后一维最快）——meshgrid 展平（`AZ(:)` 型 az/el 网格）必须 `order='F'`，否则 2-D DBF 谱的峰值索引查表会错位。

规则：凡 MATLAB 代码出现 `(:)`、`find`、`reshape`，先确认索引域与展平序，再写 numpy 对应。

# 修法（坑 1）

mask 与数据都 `reshape(-1)`（C 序）后统一用扁平索引，自洽即可，不必追求与 MATLAB 列主序逐位同序。

# 证据

实测 AFM761 DA 流 `limit_da_objects_per_range` 在候选数超上限时 IndexError（snr 排序索引值达 234 而候选仅 41 个）。
