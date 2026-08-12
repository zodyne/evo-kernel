---
id: ucm221-tracker-macros-in-ucm221-track-repo
type: fact
status: candidate
scope: project:ucm221
domain: tracking
tags: [ucm221, tracking, gtrack, static-lib, multi-repo, grep]
triggers:
  - "在 ucm221-pointcloud-2.0 里 grep 航迹/跟踪器宏（DELETE_THRESHOLD 等）搜不到"
  - "找 UCM221 跟踪器参数/阈值定义（确认、删除、滑行帧数）"
  - "libucm221 里跟踪相关目录只有 .a 静态库没有源码"
  - "grep 全空就断言某宏/参数不存在（失败信号）"
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fbb55-aff3-7aa0-937b-51eaddbeab92
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [episode-ucm221-project-overview, offline-radar-datapath-derived-params-reconcile]
---
# UCM221 跟踪器以 .a 静态库进 libucm221，航迹管理宏在独立仓库 ucm221_track

## 主张

UCM221 的跟踪器（gtrack/航迹管理）**源码不在 ucm221-pointcloud-2.0 里**——libucm221 只链接预编译静态库（`libucm221/src/tracker/lib/libgtrack-darwin-arm64.a` 等），航迹管理宏（如 `TRACK_CONFIRMED_DELETE_THRESHOLD`）定义在独立仓库 `~/Dev/ucm221_track`。在 pointcloud-2.0 里 grep 跟踪器参数全空**不代表不存在**，先 `ls -d ~/Dev/ucm221_track` 确认并行仓库再去那边搜。

## 证据

- 在 pointcloud-2.0 里 6+ 轮 grep（`DELETE_THRESHOLD` / `CONFIRMED_DELETE` / `deleteThresh` / `-i "delete|coast|unassoc|miss"`，覆盖 `libucm221/include`、`libucm221/src`、`include/track/*.h`）全部空输出。
- `ls libucm221/src/tracker/lib` → 只有 `libgtrack-darwin-arm64.a libgtrack-linux-arm...`，无源码。
- `ls -d ~/Dev/ucm221_track && grep -n TRACK_CONFIRMED_DELETE_THRESHOLD ~/Dev/ucm221_track/include/track_common.h` → `73:#define TRACK_CONFIRMED_DELETE_THRESHOLD (24U) // 确认航迹最多滑行 0.6 s`，一次命中。

## 边界

- 只适用于跟踪器核心；信号处理（signalProcess）、faf 等模块源码就在 pointcloud-2.0/libucm221 里，正常 grep 即可。
- ucm221_track 是并行仓库，两份代码的版本对应关系未在本会话核实，改参数前要确认 pointcloud-2.0 链接的 .a 与该源码版本一致。
