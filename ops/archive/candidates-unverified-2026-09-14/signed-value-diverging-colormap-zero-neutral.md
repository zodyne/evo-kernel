---
id: signed-value-diverging-colormap-zero-neutral
type: lesson
status: candidate
scope: global
domain: visualization
tags: [colormap, signed-quantity, diverging-scale, percentile-normalize]
triggers:
  - "给有正负有零的物理量（速度、误差、残差）配色标"
  - "零值落在色标端点/深色上，静止样本读不出来（失败信号）"
  - "分布明显偏一侧，用单一对称量程浪费半条色标"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:9c7257e9
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
related: [radar-doppler-bin-wraparound-unroll-first]
---

# 有符号量着色：双色发散 + 中性色中点，两臂各自分位归一

**主张**：有符号物理量（速度/误差/残差）的色标用**双色发散**，零值必须落在"读作没有"的中性色上（亮灰而非深灰——深色底上深灰静止点会沉进背景）；分布偏一侧时两臂按各自分位（如 0.5/99.5）分别归一，不要用单一对称量程让半条色标闲置。

**为什么**：单向渐变会让零值落在色标端点，"静止"和"某方向极值"同色，读图必误判；对称量程在偏态分布下另一臂没有数据，有效分辨率减半。

**边界**：量本身环绕（如未解的多普勒门号）时先解环绕再上色，否则零速处颜色突变（见 related）。

**证据**：session 9c7257e9，viewer_filtered.py 速度着色（蓝←静止→红，中点亮灰）实测 0709_2 偏负侧分布。
