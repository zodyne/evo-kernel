---
id: macos-bsd-awk-no-asort-asorti
type: lesson
status: validated
scope: global
domain: macos-tooling
tags: [awk, bsd, macos, sort]
triggers:
  - "macOS 上跑 awk 脚本报 calling undefined function asort"
  - "把 Linux / gawk 里用 asort/asorti 的脚本照搬到 macOS"
  - "awk 里想按值排序关联数组，asort 报 undefined function（失败信号）"
  - "macOS 命令行排序，不确定 awk 内建排序与 gawk 的差异"
created: 2026-09-15
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09fda-34ee-75f1-8fc4-18b82cc88983
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
---
一句话主张：macOS 默认 `awk`（BWK / one-true-awk，不是 gawk）没有 `asort()` / `asorti()` 函数，脚本里调它会直接报 `awk: calling undefined function asort` 退出；要排序要么换 `gawk`，要么把排序交给外部 `sort` 命令，别把 gawk 的数组排序当可移植的 awk 内建能力。

为什么：`asort` / `asorti` 是 gawk 的扩展，BSD 系 awk 不实现；macOS 上 `awk` 默认就是非 gawk 版本。所以从 Linux 习惯照搬的 awk 脚本在 macOS 上会静默升级成硬失败——不是排序结果错，而是函数调用当场 undefined，整条命令挂掉。

边界/证据链接（均来自会话 01a09fda 的命令 ↔ 结果切片）：
- 切片里一段 `for i in $(seq 1 20); do curl ...; done | awk '{...}'` 的 20 次 TCP+TLS 采样脚本，运行后直接报 `awk: calling undefined function asort  input record number 40, file ...`，命令立即失败——这正是用 asort 做数组排序时撞上的。
- 未在切片中看到用 `gawk` 或外部 `sort` 修复后的成功输出（会话随即改用 Python `/tmp/netprobe.py` 重写采样逻辑），所以"换 gawk / sort 即修复"这一半是补救建议而非本次实测；引用时对修复侧留一分保守。
- 2026-09-16 独立复验（交互模型，非原会话）：`awk 'BEGIN{a[1]=1; asort(a)}'` → `awk: calling undefined function asort`（BWK awk 现证）
