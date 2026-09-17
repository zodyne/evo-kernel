---
id: selfcal-holdout-crossframe-is-fake-independence
type: lesson
status: candidate
scope: global
domain: radar-calibration
tags: [自标定, 验证集, 留出格子, 跨帧, 假独立, dev8t8r]
triggers:
  - 靠留出格子或跨帧验证自标定的泛化能力
  - 静止场景下换帧/换距离bin 当作独立验证集（失败信号：假独立）
  - 自标定结果在不同数据上是否一致，想找真判据
  - 多组标定都能把谱峰立起来，但报出的方位角是否一致
  - 邻近距离bin 被当作独立样本喂进验证
created: 2026-08-24
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-24-15-36-49-006-p1ft
last_verified: 2026-08-24
superseded_by: null
schema_version: 1
related: [calibration-set-not-validation-set]
---

# 自标定类工作的验证陷阱：靠「留出格子/跨帧」验证泛化是假独立

自标定类工作的验证陷阱：靠'留出格子/跨帧'验证泛化是假独立。

## 为什么

静止场景下不同帧是同一批散射体；按功率挑的相邻距离bin是同一散射体的距离旁瓣(实测|内积|0.86-0.98)。

## 真判据

真判据是换一批数据重新拟合，看解本身是否一致——dev8t8r 里四组标定各自都能把谱峰立到13-21dB，报出的方位角却相差中位83度。
