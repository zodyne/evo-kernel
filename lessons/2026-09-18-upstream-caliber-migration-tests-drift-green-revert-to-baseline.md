---
id: upstream-caliber-migration-tests-drift-green-revert-to-baseline
type: lesson
status: candidate
scope: global
domain: radar-dsp
tags: [radar, migration, oracle, parity, regression, caliber]
triggers:
  - 把算法链「口径真源」迁移到上游/新实现后，测试全绿但真实数据点云/RD 矩阵错
  - 怀疑 parity/契约测试被顺手改成以新上游为准、跟着错上游一起绿
  - 想确认「测试绿」是否等于「口径正确」
  - 迁移后需要用独立参考实现对拍真实数据、决定是否回退默认后端
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0acf9-125a-77c1-a593-51a9c2c0ccaa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related:
  - bytes-exact-oracle-gate-for-pipeline-port
  - fft-memcmp-self-consistency-no-golden-binding
  - dual-impl-cross-check-tolerance-grid-anchored
---

# 口径真源迁移：parity/契约测试会跟着错上游一起漂绿，回退到独立参考基线

## 主张

把算法链「口径真源」迁移到上游实现时，迁移动作会顺手把 parity/契约测试改成以新上游为准，于是「测试全绿」变成伪信号；口径正确性只能靠一个独立于上游的参考实现（黄金参照）对拍真实数据来仲裁，发现偏离就回退默认后端到基线。

## 为什么

SPC865 先把口径真源迁到 algommw（上游，commit 68bfade），并声称 parity/契约全绿，但用户拿 QD-6 银五暗箱数据 + 现场录像判点云/RD 矩阵错误。用 MATLAB 参考实现（docs/awr294x_spc865_v1.m）的忠实 Python 移植做 oracle 对拍，发现远波束能量中位差 19.2 dB（参考 90.5 vs 我们 71.2）。根因是 CFAR 训练窗的 off-by-one 与检测矩阵统计量口径（是否乘通道数）。关键：契约测试 test_dsp_baseline.py 的期望值早已被改成上游口径（20·log10(RX·tx_count·wr·wd)），parity 用例也被改写成「验证上游统计量」，所以它们跟着错上游一起绿，不代表口径对。

## 做法

保留/写一个不共因的参考实现对拍闸门（本会话是 matlab_ref.py 逐格对拍，修好后远波束 90.5 vs 90.5、最大差 5.68e-14、掩膜逐格一致、85 检出全一致），并把默认后端回退到 MATLAB 基线（commit「口径复核：默认回到 MATLAB 基线」）。

## 边界/反例

别把「parity 测试」当独立闸门——它可能与被审实现共用同一套（错）上游语义；真正的仲裁者是独立参考实现 + 真实数据，不是测试套件。相关机制见 bytes-exact-oracle-gate-for-pipeline-port（移植加 oracle 闸门）、fft-memcmp-self-consistency-no-golden-binding（测试只验两路径自洽没 golden 绑定）。

## 证据

- matlab_ref.py 逐格对拍：「远波束 90.5→90.5、5.68e-14、85→85、掩膜逐格 True」
- 契约测试期望值从「乘通道数」回退到「不乘通道数」（68bfade^ vs 当前）
- pytest test_matlab_reference_parity.py 7 passed
