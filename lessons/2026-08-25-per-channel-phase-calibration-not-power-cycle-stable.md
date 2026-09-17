---
id: per-channel-phase-calibration-not-power-cycle-stable
type: lesson
status: candidate
scope: global
domain: radar-calibration
tags: [逐通道相位标定, 开机, MMIC, TX相移器, LO分频器, DDMA, dev8t8r]
triggers:
  - 逐通道相位标定不跨开机，热机标定带到下一次开机失效
  - 暗室标定在外场数据上完全失效，怀疑通道编号错位
  - 穷举 TX/RX 循环移位排除通道编号错位
  - 每次开机/拆装后是否需要重新采正前方角反射器
  - 看报出的角度值判断标定好坏（失败信号：估计器永远返回 argmax）
created: 2026-08-25
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-08-25-06-52-43-507-zi49
last_verified: 2026-08-25
superseded_by: null
schema_version: 1
related: [doa-0deg-corner-unconstraining-cross-beam-consistency]
---

# 逐通道相位标定不跨开机

逐通道相位标定不跨开机。

## 证据

dev8t8r: 暗室0度标定在同一次开机内23分钟跨度仍给0.28度RMS，带到42天后另一次开机的外场数据完全失效——方位峰旁比只从1.81到3.19dB，而该数据自标定能到17.75dB。两份解扣掉2参数规范斜坡后仍差47.6度rms；穷举TX/RX各8种循环移位共256组也没有断层式赢家(最好14.60 vs 次好12.39)，排除通道编号错位。机制很可能是MMIC的TX相移器/LO分频器每次上电相位状态不同(DDMA正是用TX相移器打码)。

## 作业含义 / 边界

每次开机、每次拆装后都必须重新采一次正前方角反射器。诊断要点：看峰旁比而不是看报出的角度值，估计器永远返回argmax所以永远打印一个数。
