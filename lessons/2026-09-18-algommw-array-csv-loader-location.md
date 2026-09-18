---
id: algommw-array-csv-loader-location
type: fact
status: candidate
scope: project:algommw
domain: codebase-map
tags: [algommw, array, csv, core_bind, load_array_csv]
triggers:
  - "algommw 阵列布局 CSV 的加载入口函数在哪"
  - "把 algommw 上游搬进 Python 仓库，找阵列布局读取实现"
  - "load_array_csv 签名 / 返回类型 / 所在文件"
  - "在 algommw python/core_bind 下找数组/阵列配置加载"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ad4f-eaf6-77c1-a593-51b2e084f190
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
---

algommw 的阵列布局 CSV 加载入口是 `python/core_bind/config.py:345` 的
`load_array_csv(csv_path: Path, grid_rows: int, grid_cols: int) -> dtypes.Array`，调用点在 471 行。

为什么：本次侦察目标是把 algommw 上游搬到 Python 仓库、直接吃 SPC865/TI AWR2944 采集件，
阵列布局读取是入口之一，已有实现直接复用即可，无需另写 CSV 解析。

证据：`grep -n "load_array_csv|def load_profile" python/core_bind/config.py` →
`345:def load_array_csv(csv_path: Path, grid_rows: int, grid_cols: int) -> dtypes.Array:` 及 471 行调用。
