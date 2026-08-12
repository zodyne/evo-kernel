---
id: calibration-physics-first-sweep-robustness-only
type: lesson
status: candidate
scope: global
domain: algorithm-calibration
tags: [calibration, parameter-tuning, cfar, tracking, oracle]
triggers:
  - "物理标定 vs 参数扫描"
  - "调参调到和一致性检查自洽"
  - "单测全绿但参数值是错的"
  - "bench 是记分牌不是闸门"
  - "合成真值能不能当验收标准"
created: 2026-07-23
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:95d881b1
last_verified: 2026-07-23
superseded_by: null
schema_version: 1
---

**主张**：算法参数标定要分清三件事：① 值从物理推导来，参数扫描只做鲁棒性体检、不做寻优——扫出来的「最优」会退回「调参调到与一致性检查自洽」的共模陷阱；② 实现正确性单测（C 是否匹配参考算法）不验参数值选得对不对——物理上错的值照样过实现单测，标定需要「参数质量」判据；③ 验收前确认 bench 覆盖链路层级：合成点云 bench 绕过前端检测层，只能验跟踪层参数。

**为什么**：algommw 项目有 2026-07-17 共模标度错误的前科（三层验证同时失守）。track_bench 的合成真值由独立生成器产出，作验收 oracle 合法，但作优化目标即危险；CFAR 检测层（guard/win/阈值）没有逐检测点合成真值，需用 adc_sim 合成采集 + truth.csv 从链路最前端喂入来验，与跟踪层是完全不同的验证 regime。且 CFAR 输出是跟踪输入，检测层参数错着，跟踪标定就坐在坏输入上——顺序不能反。

**边界**：「定稿/done」要先定义成可判的四件套（含回归地板），bench 只打印指标没有 pass/fail 阈值时它就不是闸门。

**证据**：2026-07-23 algommw grilling 会话，逐步锁定标定方法论与范围。
