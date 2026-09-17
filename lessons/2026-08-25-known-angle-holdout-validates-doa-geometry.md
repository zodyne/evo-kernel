---
id: known-angle-holdout-validates-doa-geometry
type: lesson
status: candidate
scope: global
domain: radar-doa
tags: [MIMO, 测角, 留出验证, 角反射器, 通道序, DDMA, 帧头]
triggers:
  - MIMO 雷达测角排查找不到终局判据
  - 0° 标定好但目标一离开正前方就崩
  - 验证阵列坐标表/TX↔子带映射/通道序/DDMA解复用/导向矢量符号是否正确
  - 盘上帧头被重复写、按固定步长读把帧头当数据喂进 FFT（失败信号）
  - 想用已知角度的参考目标做留出角度验证
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-25-06-02-53-403-aa20
last_verified: 2026-08-25
superseded_by: null
schema_version: 1
related: [doa-0deg-corner-unconstraining-cross-beam-consistency]
---

# MIMO 雷达测角排查的终局判据：已知角度参考目标 + 单角度标定、其余角度留出验证

MIMO雷达测角排查的终局判据：拿一份已知角度的参考目标数据，用单个角度标定、在其余角度上留出验证。

## 为什么

dev8t8r 用 0° 暗室标定，−50..+50 十个留出角度 RMS 0.28°(标定前 57.9°)。这一步同时验证了阵列坐标表/TX↔子带映射/通道序/DDMA解复用/导向矢量符号——它们在 0° 上全都验证不出来(理想导向矢量是全1，任何错误都被标定吸收)，但目标一离开正前方就崩。

## 反证

参考角谎报10°，RMS 从0.28跳到12.64。

## 边界

另:盘上帧头可能被重复写，按固定步长读会把帧头当数据喂进FFT，应按 magic 定位并只保留整帧。
