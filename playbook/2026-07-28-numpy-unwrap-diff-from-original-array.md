---
id: numpy-unwrap-diff-from-original-array
type: lesson
status: deprecated
scope: global
domain: numerical-computing
tags: [c, numpy, porting, unwrap, signal-processing, in-place]
triggers:
  - "把 numpy 的 np.unwrap（或任何 差分→相位修正→cumsum 的流式算法）从 Python 移植到 C"
  - "C 移植版与 numpy 参照对不齐，但公式逐行核对都一样"
  - "移植顺序依赖算法时，顺手用原地写回（in-place）数组来省一次拷贝"
  - "边算边改写相位数组，导致下游差分被上一步修正污染（失败信号）"
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:fb616292-c015-42e4-9987-16229ad221f3
last_verified: 2026-07-28
superseded_by: skill:matlab-to-python-migration
schema_version: 1
---
# 移植 np.unwrap 到 C：差分必须取自原始数组，禁止边算边就地改写

**主张**：`np.unwrap` 这类"算相邻差分 → 按 2π 修正 → 累加"的算法，**差分必须始终取自原始相位数组**，先对每个元素整体算出修正量、最后一次性 `cumsum`。若边算边就地改写数组（拿修正后的值去算下一步差分），上一步的相位修正会被混入下一步的差分计算，后续所有 unwrap 结果顺次错位，且**无报错**。

**根因**：差分依赖前序输出；一旦把修正写回输入数组，下一步 `diff = arr[i] - arr[i-1]` 里的 `arr[i-1]` 已经是被改写过的值，差分语义被破坏。

**修法**：保留原始输入只读，所有差分从原始数组取；修正量算到独立的输出数组，再 cumsum。UCM221 的 hpr（横向相位差）特征 C 移植即踩此坑。

**反例/边界**：仅当算法数学上"差分与历史输出无关"（纯映射）时才可就地写；凡是"修正量依赖前序结果又写回同一缓冲"的流式算法都中招——这是移植 numpy → C 的通用坑，不限 unwrap。

**证据**（session fb616292）：
- 捕获：`inbox/capture-2026-07-27-14-36-51-742-ee3f.md`——"np.unwrap 的差分必须取自原始相位数组(先整体算修正量再cumsum), 边算边就地改写会把上一步修正混入下一步差分"。
- 修复后 golden 复验：`[PASS] 阈值 hpr python=1.000000 c=1.000000`。
