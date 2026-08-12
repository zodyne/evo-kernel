---
id: nan-poisons-minmax-aggregation
type: lesson
status: candidate
scope: global
domain: numpy
tags: [nan, numpy, aggregation, data-pipeline]
triggers:
  - "数据里引入 NaN 语义（无效点/缺失值）后，下游 min/max/量程统计"
  - "np.min/np.max 算出 nan，坐标系/网格/色标整个画不出来"
  - "给含缺失值的数据计算范围、边界框、归一化系数"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:a522a07c-f185-4449-9fd7-d0f755c0b02f
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [parser-silent-clamp-masks-out-of-range]
---

数据里一旦引入 NaN（无效点/缺失值），**必须审查下游所有 min/max/量程类聚合**：`np.min/np.max` 遇 NaN 直接传染成 nan，参考系量程、网格、色标会整体崩掉且不报错。

为什么：UCM221 把出圆点改为 NaN 后，参考系 `r_max = nan`（不滤 NaN 时），网格直接画不出来；滤 NaN 后 `r_max = 317.8` 正常。NaN 传染是静默的——不抛异常，只让结果全变 nan，定位时容易先去怀疑绘图层。

对策：聚合前显式滤 NaN（`r[~np.isnan(r)]`）或改用 `np.nanmin/np.nanmax`；改数据语义（引入 NaN）时把"下游聚合点清单"作为改动的一部分。

证据：会话内命令输出——"不滤 NaN: r_max = nan / 滤 NaN 后: r_max = 317.8（本文件出圆 859 点 → 参考系量程会整个变成 nan，网格直接画不出来）"。
