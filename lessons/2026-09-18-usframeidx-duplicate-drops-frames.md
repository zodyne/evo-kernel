---
id: usframeidx-duplicate-drops-frames
type: lesson
status: candidate
scope: project:algommw
domain: radar-data
tags: [usframeidx, frame-index, dict-key, silent-data-loss, sr61]
triggers:
  - "以传感器帧号 usFrameIdx 当落盘/缓存字典键、去重键或排序键"
  - "回放/落盘后帧数与原始 .bin 对不上，少若干帧且全链路无报错（失败信号）"
  - "SR61 采集件按帧号拼接/对齐，怀疑帧号有重复"
  - "做丢帧检测时只抽一个 .bin 看到 dups=0 就想放过（失败信号：单文件干净不代表整批干净）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a575-5bdd-7353-8a3d-42cfac95e3a6
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [natural-sort-numeric-suffix-multifile]
---

# usFrameIdx 不唯一：拿它当字典键会静默丢帧（SR61 实测 1200 帧丢 20）

## 主张
采集数据里传感器自报的帧号 `usFrameIdx` **不保证唯一**，不能当落盘/缓存的字典键或去重依据——重复帧号互相覆盖，帧数静默变少且没有任何报错。键位应改用「读入顺序号」或 `(文件, 文件内序号)` 组合键。

## 证据（本次审查实录）
- 全量扫 12 个 SR61 `.bin`：`raw frames: 1200 unique: 1180 dropped: 20`——**20 帧帧号重复**。
- 单个文件看不出来：`61_car20km_2025-10-23-16-50-03_0.bin frames=100 ... dups=0`，只抽一个文件检查会得出"没问题"的错误结论。
- 同一模式在仓库里有两处：`python/radar_viz/pipeline.py:417-424`（落盘以 `usFrameIdx` 为字典键）、`python/radar_viz/view_tracks_3d.py:95`（`det[item.fi] = item.det`）。
- 这是本次审查的 finding #1（medium）：重复键导致丢帧，而落盘层没有任何告警。

## 边界
- 现象取自 SR61 采集（12 个文件合计 20 处重复），不保证每个批次都复现——**丢帧检测必须全量扫**，单文件 `dups=0` 不构成结论。
- 若下游只想要"最后写入的那一帧"，用帧号当键看似无碍，但覆盖顺序不可控、结果不可复现，仍应换键。
