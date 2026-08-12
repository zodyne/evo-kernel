---
id: parser-silent-clamp-masks-out-of-range
type: lesson
status: candidate
scope: global
domain: signal-processing
tags:
- numpy
- parser
- data-integrity
- nan
- radar
triggers:
- 解析/坐标转换函数里用 np.clip / clamp 把输入夹进合法域
- 越界/异常样本在输出里表现为边界上的大量堆积值（如角度全是 ±90°）
- 怀疑上游（FPGA/传感器）算错，但其实是解析层静默夹出来的假点
- 给数据解析层加异常标记或过滤逻辑，纠结丢点还是留点
created: 2026-08-01
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: session:a522a07c-f185-4449-9fd7-d0f755c0b02f
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related:
- ucm221-off-disk-uv-geometric-reject
---

解析/转换层**不要静默 clamp 越界输入**：越界样本应显式返回 NaN 并附布尔标志位（如 `off_disk`），把"数据有问题"保留为可诊断信号。

为什么：UCM221 `uv_to_xyz` 把 `u` 夹进 `[-cos_el, cos_el]`，导致全部出圆点（u²+v²>1）被夹成 |az|=90° 的"合法"假点——000028 数据集 3,559 个假点全部来自出圆点，且与真点无法区分，极易把解析缺陷误判成 FPGA 测角算错。改成出圆点返回 NaN + `off_disk` 标志后，三个数据集验证 NaN 与出圆标志逐点一致，且**圆内点与旧实现逐位相同**（回归无差）。

边界：NaN 语义会传导到下游聚合（见相关提案 nan-poisons-minmax-aggregation）；不想让 NaN 进数据流时，至少保留标志位让下游自行决定。

证据：会话内 numpy 验证脚本输出——"旧: |az|≥89.9° 的假点 3,559（其中出圆 3,559）/ 新: NaN 与出圆标志逐点一致 True / 圆内点与旧实现逐位相同: True"。
