---
id: numpy-complex-scalar-division
type: bullet
status: validated
scope: global
domain: numerical-computing
tags:
- numpy
- c
- porting
- complex-division
- numerical-parity
triggers:
- 把含复数数组除标量的 numpy 代码移植到 C，逐点比对对不上
- 复数数组归一化（cal 归一化 / xn 归一化）C 侧与 numpy 参照差在最后几位
- 在 C 里把 complex/float 实现成实部虚部分别相除
- 跨语言数值验收：公式逐行核对一致，结果仍有系统性尾差（失败信号）
created: 2026-08-12
evidence:
  helpful: 0
  harmful: 0
verified_by: command
source: 人工（整理 inbox/capture-2026-07-27-14-36-51-742-ee3f.md）
last_verified: 2026-08-12
superseded_by: null
schema_version: 1
related:
- numpy-unwrap-diff-from-original-array
- acceptance-build-ffp-contract-off
---
# numpy 的 complex/float 走复数除法语义：退化为乘倒数，不是逐分量相除

**主张**：numpy 里 `complex 数组 / float 标量` 走的是**复数除法**语义，实际计算退化为**乘倒数**（先算 `1/s` 再乘），而不是"实部÷s、虚部÷s"的逐分量相除。C 移植若按逐分量相除实现，两种舍入路径不同，数值与 numpy 参照存在尾差。

**为什么**：复数除法与逐分量实数除法的舍入次序不同——乘倒数多一次 `1/s` 的舍入。UCM221 C 移植在**三处**命中此坑：cal 归一化、xn 归一化、A_grid 除 sqrt(6)。

**反例/边界**：只在要求与 numpy 参照逐点可比（验收/golden 比对）时才是坑；不比对参照的独立实现逐分量相除完全合法。

**证据**：UCM221 C 移植对齐 numpy 会话（capture-2026-07-27-14-36-51-742-ee3f），三处归一化按复数除法（乘倒数）改写后与参照对齐。
