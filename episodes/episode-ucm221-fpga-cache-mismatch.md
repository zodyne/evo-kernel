---
id: episode-ucm221-fpga-cache-mismatch
name: UCM221 测角算法与 FPGA 结果不一致排查
type: episode
status: validated
scope: [debugging, hardware-software-integration]
domains: [ucm221, radar, fpga]
triggers:
  - FPGA
  - 测角算法
  - 结果不一致
  - 数据缓存
  - 缓存未清空
evidence:
  helpful: 0
  harmful: 0
verified_by: human
last_verified: '2026-04-03'
created: '2026-07-25'
---

# UCM221 测角算法与 FPGA 结果不一致排查

## 问题现象

信号处理侧测角算法与 FPGA 实现输出结果不一致。

## 排查过程

- 初步怀疑算法实现差异；
- 进一步定位到**数据采集缓存未清空**；
- 缓存未清空导致解析处理了错误的角度数据。

## 解决方案

清空数据采集缓存后重新采集，角度数据恢复正常，问题关闭。

## 可复用经验

当算法侧与 FPGA 侧结果不一致时，在对比算法实现之前，先确认：
1. 数据采集缓存是否已清空；
2. 帧/缓冲区是否已正确复位；
3. 两侧读取的数据地址是否对齐。

这类问题常表现为「角度数据错误」而非「算法逻辑错误」，容易误排查方向。

## 来源

- 原 OpenClaw 知识库：`vault/10-Projects-Active/UCM221/UCM221_算法与软件推进会议纪要.md`
- 迁移时间：2026-07-25
- provenance: [imported] 经人审改写后 curate 入库
