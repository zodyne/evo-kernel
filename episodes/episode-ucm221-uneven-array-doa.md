---
id: episode-ucm221-uneven-array-doa
name: UCM221 非均匀阵列暗室测角问题定位
type: episode
status: validated
scope: [debugging, signal-processing]
domains: [ucm221, radar, doa]
triggers:
  - 非均匀阵列
  - 暗室测角
  - 俯仰相位模糊
  - 长短基线解模糊
  - 角度估计偏差
evidence:
  helpful: 0
  harmful: 0
verified_by: human
last_verified: '2026-06-26'
created: '2026-07-25'
---

# UCM221 非均匀阵列暗室测角问题定位

## 问题现象

非均匀阵列暗室测角中，大角度俯仰估计出现错误。

## 根因定位

大角度俯仰估计错误由**俯仰通道相位模糊**导致。

## 解决过程

1. **水平方向测角**：±55 度范围内一致性与准确性良好；
2. **长短基线解模糊**：使大角度俯仰估计基本正确，但仍有约 10 度偏差；
3. **非线性拟合**：将角度估计偏差进一步控制在约 3 度。

## 遗留问题

非线性拟合后的角度估计是否能工程应用仍需进一步分析论证。

## 可复用经验

- 非均匀阵列大角度俯仰测角需先检查相位模糊；
- 长短基线解模糊后通常仍有残余偏差，需配合非线性拟合或查找表补偿。

## 来源

- 原 OpenClaw 知识库：`vault/10-Projects-Active/UCM221/UCM221_Software_Progress.md`
- 迁移时间：2026-07-25
- provenance: [imported] 经人审改写后 curate 入库
