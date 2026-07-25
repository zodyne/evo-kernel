---
id: fact-ucm221-super-resolution-arm-performance
name: UCM221 超分辨算法 ARM 移植性能
type: fact
status: validated
scope: [coding, optimization]
domains: [ucm221, radar, super-resolution, arm]
triggers:
  - 超分辨算法
  - ARM 移植
  - 运算时间
  - 查表法
  - 实时性
evidence:
  helpful: 0
  harmful: 0
verified_by: human
last_verified: '2026-07-10'
created: '2026-07-25'
---

# UCM221 超分辨算法 ARM 移植性能

超分辨函数已完成 ARM 移植，当前性能数据如下：

| 实现方式 | 平均运算时间 |
|---|---|
| 当前 ARM 移植版本 | 0.2 ms / 点 |
| 完整查表法实现（预计） | 0.1–0.15 ms / 点 |

## 工程含义

- 当前 0.2 ms/点 已可投入初步验证；
- 若需进一步压缩运算时间，优先推进完整查表法实现；
- 2026-07-10 与南航完成算法交互结项，后续转入 FPGA 实现和验证。

## 来源

- 原 OpenClaw 知识库：`vault/10-Projects-Active/UCM221/UCM221_Software_Progress.md`
- 迁移时间：2026-07-25
- provenance: [imported] 经人审改写后 curate 入库
