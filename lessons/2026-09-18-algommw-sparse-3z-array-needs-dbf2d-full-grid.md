---
id: algommw-sparse-3z-array-needs-dbf2d-full-grid
type: fact
status: candidate
scope: project:algommw
domain: radar-doa
tags: [algommw, afm761, dbf2d, 稀疏阵, 3-z, 角度fft快路径, profile]
triggers:
  - "给 afm761 / 稀疏 3-z 阵选 algommw 的 DOA 变体（beam 还是 dbf2d）"
  - "profile 里 [doa] variant 写 dbf2d 的原因是什么"
  - "beam 的角度 FFT 快路径报越界 / 摆不了格（失败信号）"
  - "稀疏/非均匀阵列能不能走角度 FFT 快路径"
  - "afm761 上 music/dml 返回 eErrNotImpl"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5b6d-7353-8a3d-42ca582bd179
last_verified: 2026-09-15
superseded_by: null
schema_version: 1
related: [algommw-doa-beam-1d2d-auto-split]
---

afm761 是 **16/175 稀疏 3-z 阵**（z 半λ 网格 −3..1，`grid_rows = 5`），beam 变体的**角度 FFT 快路径"摆不了格"（z=−3 越界）**，所以该 profile 的 `[doa]` 变体必须用 **dbf2d**——按 `[doa.scan]` 给的网格做全网格复加权扫描；且 **music/dml 在该阵上直接 `eErrNotImpl`**。这不是风格选择，是阵列几何对变体选型的硬约束。

## 证据（切片内命令 ↔ 结果）

- `grep -n -A30 "\[doa\]" profiles/afm761_ddm/profile.toml` 命中 `123:[doa] 124-# 变体名 dbf2d = "必须按 [doa.scan] 给的网格扫描"(全网格复加权)。afm761 是 16/175 125-# 稀疏 3-z 阵:beam 的角度 FFT 路径摆不了格(z=−3 越界…`（切片在该行截断）。
- 同 profile `[array]`（`grep -n -A12 "\[array\]" ...`）：`file = "afm761_array.csv"`、`grid_rows = 5                  # z 半λ 网格 −3..1 共 5 行`（profile.toml:177-179）。
- `grep -rn "NotImpl\|NotImplemented" docs/*.md` → `docs/afm761_integration_study.md:256: music/dml → eErrNotImpl（§8.1 实证 music 不适用 3-z 阵）`。
- 对照：sr61_tdm（4x4 均匀 AOP 阵，`profiles/sr61_tdm/sr61_aop.csv` 注释给逐天线位置）的 `[doa]` 没有这一层 dbf2d 约束（切片只到 `167:[doa] 168-varia...`，未展开）。

## 边界

- 判据是"阵列能否落进 beam 角度 FFT 快路径的规范网格"，**不要外推成"所有稀疏阵都不能用 beam"**；z=−3 越界具体发生在哪一层（阵元 z 行 vs 快路径正弦格）切片未展开。
- 与 `algommw-doa-beam-1d2d-auto-split` 互补：那条讲 beam 内部 1D/2D 分流判据（xPosZ 极差 < λ/8），本条讲为什么 afm761 根本不能走 FFT 快路径、只能全网格复加权。
