---
id: doppler-velocity-sign-receding-negative
type: lesson
status: candidate
scope: global
domain: radar-dsp
tags: [radar, doppler, sign-convention, fftshift, rd-map]
triggers:
  - 核对/审查雷达多普勒速度符号约定（远离=正还是负）
  - 报「运动目标速度方向反了 / 去向目标读成正速度 / 靠近读成负速度」
  - 画 RD 谱/热力图时速度轴左边界或 bin0 语义拿不准
  - 复现雷达链路单测全绿但真实数据速度符号错
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0acf9-125a-77c1-a593-51a9c2c0ccaa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related:
  - suc221-elevation-display-sign-convention
  - dual-impl-cross-check-tolerance-grid-anchored
---

# 多普勒速度符号约定：远离=负，用往返距离漂移做物理对拍

## 主张

雷达多普勒速度符号约定是「远离（距离增大）= 负速度」，且必须用同一目标「去程 + 回程」的距离漂移做物理对拍才能定死——单看轴/公式自洽测不出「符号整体镜像」这种错。

## 为什么

SPC865 离线链把口径真源迁到上游后，速度轴符号整体镜像了。QD-6 银五批次里目标走了完整往返：去程 5→95→280 m（距离增大=远离）读成 +3.09/+2.32 m/s ✗，回程 178→77→26 m（距离减小=靠近）读成 −2.32 m/s ✗。符号整体镜像不是随机误差而是约定错，单元测试自洽（轴两端对称）根本测不出来，用户是拿现场录像报「去向目标在 RD 谱里是正速度」才暴露。

## 做法

用物理事实当判据——去程距离漂移为正（远离）时速度必须为负，回程距离漂移为负（靠近）时速度必须为正。据此把 velocity_axis_mps 翻转：fftshift 后 bin0 = 靠近侧最大正速度（+12.36 m/s）、bin32（零速）= 0、bin63 = 远离侧最大负速度（−11.98 m/s），并加 test_doppler_sign.py 闸门。

## 边界/反例

别把速度轴当距离轴——距离轴 bin0 = −ΔR/2，但多普勒轴 fftshift 后 bin0 = 靠近侧最大正速度，绘图/网面左边界必须从 −32·ΔV 起，照抄距离轴写成 −ΔV/2 会整条轴错位。俯仰角也有同款符号约定坑（见 suc221-elevation-display-sign-convention），但那是角度、这是速度，不能互相套。

## 证据

- commit d8412d0「多普勒符号约定修正：远离（去向）=负速度」
- 往返对拍：「去程应负实得正、回程应正实得负」（符号整体镜像）
- pytest tests/test_doppler_sign.py 7 passed
