---
id: shared-empty-array-constant-arity-must-match-column
type: lesson
status: validated
scope: global
domain: python
tags: [numpy, npz, shape, empty-array, contract, serialization]
triggers:
  - "用 np.savez_compressed 落盘，给不同 arity 的列各配一个空集兜底数组"
  - "写/审查把多列打包进 npz 的序列化代码，空集时 shape 要和契约一致"
  - "复用一个 np.zeros((0,K)) 常量给 1-D 列当空值（失败信号：1-D 列也变 (0,K)）"
  - "npz 各键的 shape 契约被下游按 (T,)/(T,3) 分列取用，空集 shape 漂了"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a6a9-7d3f-7353-8a3d-42d9bff20726
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

给不同 arity（列数）的列落盘时，不要复用同一个固定 shape 的空数组常量当空值兜底：`EMPTY3 = np.zeros((0,3))` 拿去给 1-D 列 `track_vr`/`track_spd` 当空集，空集时这两列会写成 `(0,3)` 而非契约里的 `(0,)`，与同段 `track_frame`/`track_id` 的 `(0,)` 不一致，下游按 `(T,)` 取用时 shape 随数据变化而漂移。

## 为什么

`pipeline.py:26` 定义 `EMPTY3 = np.zeros((0,3))`，本意是给 `det_xyz`/`track_xyz` 这类 `(N,3)` 点云列兜底。但 `pipeline.py:451-452` 把它也套给了 `track_vr`/`track_spd` 这两个 1-D 列（`np.array(trk_vr, np.float32) if trk_vr else EMPTY3`）。独立 repro 证实：有检出、0 航迹时 `track_vr (0,3) / track_spd (0,3)`，而 `track_frame (0,) / track_id (0,)`——同一次落盘里两列 1-D、两列 (0,3)，与 `docs/view_tracks_3d_flow.md:596` 的 `(T,)/(T,)` 契约不符。空集路径只在零航迹采集出现，正常有轨时 `trk_vr` 非空、走 `np.array(trk_vr)` 正确 `(T,)`，所以这个坑只在退化场景暴露，容易被漏。

## 边界 / 反例

- 正确的空值兜底应为 `np.zeros((0,), np.float32)`，与列 arity 一致，而非共用 `(0,3)`。
- 3-D 列（`det_xyz`/`track_xyz`）用 `EMPTY3` 是对的，问题只在「1-D 列复用了 3-D 的空常量」。
- 契约核对要以文档的 shape 表为准（本例 `docs/view_tracks_3d_flow.md` 的 `.npz 键表`），并实测空集与非空集两条分支的 shape 都要与契约对齐。
- 危害面取决于消费方：本例仓内无 `np.load`（`afm761_walk_metrics.py` 直链 ChainSession 不落盘），实际风险在外部/跨采集消费者，故契约违约本身仍成立，只是 severity 要按消费方实况掂量。
