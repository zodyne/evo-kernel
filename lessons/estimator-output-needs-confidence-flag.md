---
id: estimator-output-needs-confidence-flag
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: signal-processing
tags: [estimator, confidence-flag, validity, doa, api-design]
triggers:
  - "估计器/测角/测量链只输出数值，不给可信度标志"
  - "精度边界只能事后拿两批数据对比才发现（失败信号）"
  - "大角度/低信杂比下估计发散，下游无从知晓"
  - "给算法模块设计输出接口，决定输出哪些字段"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:7cfa89db
last_verified: 2026-07-31
superseded_by: null
schema_version: 1
related: []
---

# 估计器只输出数值不给置信标志 = 运行时无法自证可信

**主张**：测量/估计链（DOA、拟合、滤波）的输出必须带**实时置信度/有效性标志**，否则单次测量无法自证是否落在可信区间——算法正确性验证过（如相位差 <1e-6°）不代表每次输出都可用，精度边界随采集条件漂移（信杂比、器件状态），没有标志位就只能靠事后跨数据集对比才发现边界在哪，运行时已经用了坏数据。

**为什么（UCM221 实例）**：测角链核心功能完整且验证正确，robust 全阵精度四项均优；但大角度精度衰减、失效边界随采集会话漂移（20260508 vs 20260713 边界不同、偏差方向相反）——输出只有角度值，运行中无法判断"这次估计可信吗"。这是唯一的功能空白，不是算法缺陷。

**边界**：标志的生成依据要来自与估计无关或弱相关的量（cost 值、argmin 是否落字典端点、通道一致性），不能用估计值本身当判据（循环论证）。

**证据**：session 7cfa89db，doa_results_summary 结果结论第 6 条（功能空白判定）。
