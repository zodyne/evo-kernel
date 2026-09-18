---
id: algommw-snapcube-uncalibrated-consumer-side-calib
type: fact
status: candidate
scope: project:algommw
domain: radar-calibration
tags: [algommw, snapcube, xCalib, 通道标定, 口径, ctypes不透明缓冲]
triggers:
  - "读/移植 algommw 的 SnapCube 或 eDoaSnapExtractRaw，判断里面有没有已施加通道标定"
  - "对拍 DOA 结果整体幅度/相位不对，怀疑 xCalib 被施加两次或漏施加（失败信号）"
  - "虚拟阵快照的通道顺序（tx*numRx+rx）与 Array_t 阵 CSV 是否同序"
  - "xCalib 是在快照里施加还是在消费侧施加"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5b6d-7353-8a3d-42ca582bd179
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [mimo-channel-order-phase-diff-exhaustive-search]
---

algommw 的 `SnapCube`/`ExtractRaw` 口径是**未施 `xCalib` 的原始 FFT 值**：通道标定**在消费侧施加**。索引序为 `idx = tx*numRx + rx`，与 `Array_t` 的阵 CSV 同序。读/移植这两个缓冲时若默认"标定已施加"，会重复施加或漏施加标定——数值偏差不崩、不报错，静默错。

## 证据（切片内 grep 命中源码注释）

- `core/include/core/types/radar.h:56`：`…无第二条数值路径);idx = tx*numRx+rx(与 Array_t 阵 CSV 同序);**未施 xCalib**`（切片截断，前文含"无第二条数值路径"）。
- `core/src/chain/chain.c:311`：`/* 标定在消费侧施加(SnapCube 存原始 FFT 值,与 ExtractRaw 同口径) */`。

## 边界

- 只说 `SnapCube`/`ExtractRaw` 这一对口径；"消费侧"具体落在哪个函数、施加几次，切片未展开。
- 快照抽取路径自述含"通道标定"步骤（`core/src/dpu/doa/snap.c` 文件头：`单 bin DFT 取天线符号 + 通道标定 + TDM Doppler 补偿`），与 SnapCube 存原始值**不是同一层口径**——不要据 snap.c 文件头推断 SnapCube 里已带标定。
- `related` 的 `mimo-channel-order-phase-diff-exhaustive-search` 处理通道顺序约定本身；本条给的是"哪个缓冲带没带标定"的口径。
