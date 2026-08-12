---
id: calibration-set-not-validation-set
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: methodology
tags: [calibration, validation, golden, thresholds, radar]
triggers:
  - 阈值/参数在某个数据集上标定完，要评估效果
  - 用标定时用的同一段数据报告新算法的提升
  - 选择验证集/评估集，手里只有一两段数据
  - 标定集上的指标明显好于其他数据，怀疑过拟合
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:da720f38-036f-42ec-820d-ce8538a4fc1f
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [bytes-exact-oracle-gate-for-pipeline-port]
---

# 标定集不能当验证集：参与标定的数据只配做 golden 回归

阈值在某数据集 A 上标定后，**A 上的一切指标都对新算法有系统性偏袒**——A 只能用作 golden/回归基准（验证「改动没破坏已验收行为」），效果评估必须换一段**未参与标定**的数据集 B。文档里要把「为什么验证集是 B 不是 A」写明，否则后来人会顺手拿 A 报指标。

**证据**（session da720f38）：UCM221 faf 的五个阈值在 0709_2（500 帧 / 19.5 万点）上标定；评估改用 000028（15,040 帧 / 190 万点，约 30 倍规模），提交 `f0198b5 docs(examples): 验证集改用 000028, 0709_2 退回 golden 比对的角色`，README 补「验证集为什么是 000028 而不是 0709_2」一节。对照数据：出圆率 0709_2 仅 0.71%，验证集上才能暴露标定集采样不到的分歧。
