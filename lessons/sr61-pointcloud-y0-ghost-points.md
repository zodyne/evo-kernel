---
id: sr61-pointcloud-y0-ghost-points
type: lesson
status: candidate
scope: project:sr61
domain: point-cloud
tags: [sr61, radar, point-cloud, csv, data-cleaning, visualization]
triggers:
  - "读取雷达点云导出 CSV 做 2D/3D 可视化"
  - "点云图里出现贴着某一坐标平面的异常点带/拖尾"
  - "SR61 点云数据可视化前的清洗/预处理"
  - "点云里大量点的某一坐标精确等于 0.0000（失败信号）"
  - "y=0 的点 range 却有几米到几十米，坐标与 range 对不上（失败信号）"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fab6b-29cf-7267-a6a6-ec475346f32c
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [playbook-ucm221-cfar-point-cloud-filtering]
---
# SR61 点云导出 CSV：y 精确为 0 且 range 很大的点是要先剔除的无效点

## 主张

SR61 雷达点云导出 CSV（列：frameIdx,frameCount,pointId,x,y,z,velocity,range,azimuth,elevation,snr）里混有一批 **`y == 0.0000` 但 range 从 0.18 m 一直到 40 m+** 的点。真实散射点的 y 不会大批精确等于零——这是导出里的无效/占位点。**可视化前先按 `(y==0) & (range>阈值)` 掩码剔除再画**，否则 3D 图被这些点污染。

## 证据（session 内命令实测）

- `awk -F',' '$5==0.0000 {print $8}'` 统计 y=0 点的 range 分布：从 0.1830 / 0.3660 / 0.9150 一直到 2.1960+，其中 **range>40 的计数 2696**——不是零星个例。
- 样本点 `8296,0,4,14.7494,0.0000,...`：x=14.75 而 y 精确为 0。
- 数据整体 y 范围 0.0000–43.6719、x 范围 −33.1–38.8；会话中实际执行的清洗为 pandas 掩码 `g = (df.y==0)&(df.range>30); dc = df[~g]`，用 `dc` 出图。

## 边界

- 掩码阈值（30 m）是按该批数据（60 度共阵）定的；换数据集先看 y=0 点的 range 分布再定阈值。
- 别和 CFAR 流水线内的虚警过滤（playbook-ucm221-cfar-point-cloud-filtering）混为一谈：本条是**导出后、离线可视化前**的清洗，发生于 pipeline 之外。
- y=0 且 range 很小（近零）的点是否为有效近距点，会话未验证，掩码只剔了 range>30 的部分。
