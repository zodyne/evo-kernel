---
id: ucm221-2ch-interferometer-bias-cal-cannot-remove
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: signal-processing
tags: [doa, interferometer, 2ch, bias, calibration, ambiguity]
triggers:
  - "用 Rx1-Rx2/Rx4-Rx5 两通道干涉仪测角"
  - "2ch 与 6ch/FPGA 测角存在恒定偏置（失败信号：cal 消不掉）"
  - "Rx4-Rx5 对角基线解 (u+v) 折叠"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:2e76dde5
last_verified: 2026-08-03
superseded_by: null
schema_version: 1
---
# 两通道干涉仪只吃相位差：恒定偏置 cal 消不掉，精度极好准度受限于基线标定

**主张**：UCM221 两通道测角——Rx1-Rx2（Δp=(1,0)，间距恰 λ/2）相位差=π·u 直接读出**无模糊**；Rx4-Rx5（Δp=(1,1)，有效基线 0.707λ）测的是 **(u+v) 折叠值**，需先知道 u 才能剥 v，"取 |v| 最小支"在 |v|>0.5 的点上会选错支（000028 有 25.3% 的点超界，实测约 9% 换支）。干涉仪只消费 2 个通道相位差，cal 的幅度信息全部约掉，因此存在 cal 消不掉的**恒定偏置**（+0.13，跨 SNR 档/跨数据集稳定，≈23° 基线相位残差/方位 7.5° 整体偏转）——典型干涉仪特征：最高 SNR 点 MAD 仅 0.0017（精度极好），准度受限于基线标定。

**为什么**：该偏置只能相对 FPGA 标定、不独立——直耦泄漏点虽稳（MAD 0.0006）但 FPGA 给它的方向不在法线方向，当不了绝对角度基准；一旦按钮标定，两组测角就不再是独立对照（需显式提示）。

**边界**：2ch 的价值是算力（每点 2 复乘 vs 6ch 网格 1878 复乘累加，约 1000×），不是精度；根治换支要引入 Rx5-Rx6 长基线联合解模糊（见 episode-ucm221-uneven-array-doa）。

**证据**：session 2e76dde5，doa_2ch.py + viewer_doa2ch.py 双组对照查看器，跨数据集偏置 0709_2 +0.135 / 000028 +0.116。
