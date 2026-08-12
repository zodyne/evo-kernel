---
id: feature-semantics-verify-against-physical-truth
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: signal-processing
tags:
- feature-design
- dc-frac
- semantics
- radar
- false-alarm
triggers:
- 按名字/直觉理解一个特征的物理含义，拿它设阈值硬剔除
- 某特征剔除了大量点，要确认它量的是不是以为的那个量
- 特征与某个无关变量强相关（如 dc 与距离强相关，失败信号）
- 真目标被过滤器成片误杀，归因到某个特征超阈
created: 2026-07-31
evidence:
  helpful: 0
  harmful: 0
verified_by: none
source: session:da720f38
last_verified: 2026-07-31
superseded_by: null
schema_version: 1
related:
- eval-negative-only-data-hides-overfiltering
---

# 特征的语义要用物理真值样本验证，不能按名字理解

**主张**：信号处理特征的"名义含义"（如 `dc_frac` = 直耦泄漏占比）必须用**已知物理真值的样本**验证后才能拿来设阈值。验证方法：找到该物理现象的确定性样本（真直耦点：近距 3~5 距离门、SNR 35 dB），看特征值是否如预期超阈；再看被特征误杀的样本是否符合名义语义。

**为什么（UCM221 实例）**：`dc` 被当作直耦泄漏占比设 0.50 阈值硬剔除，实测它实际是**以 cal 方向为中心的角度陷波器**（量的是来波方向，不是泄漏占比）：0709_2 的真直耦点 dc 中位仅 0.426、无一超阈；而 000028 上 10–20 m 真目标 56.9% 超阈被误杀。根因是物理的：校准后泄漏的通道增益被 cal 抵消，剩下的分量反映方向而非泄漏。

**边界**：不是每条特征都要重做物理实验——但凡是「按名义含义设硬阈值、且剔除量大」的特征，值得花一次真值样本对照。特征与无关变量（距离/角度）强相关是语义误判的典型信号。

**证据**：session da720f38，164 帧里 144 帧目标丢失归因到 dc 硬剔除；report §9 缺陷三。
