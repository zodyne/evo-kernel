---
id: prebuilt-lib-slot-verify-symbols-not-presence
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: c-porting
tags:
- prebuilt-static-lib
- symbol-audit
- nm
- cross-platform
- link-error
triggers:
- 仓库里存着多平台预编译 .a/.lib 槽位（lib<name>-<os>-<arch>.a）
- 某平台链接报未定义符号，本地平台却正常（失败信号：槽位漂移）
- 替换预编译库只验了文件存在/大小，没验内容
- nm 查槽位符号，发现符号集与当前 API 不符
created: 2026-08-02
evidence:
  helpful: 0
  harmful: 0
verified_by: none
source: session:7c4809cc
last_verified: 2026-08-02
superseded_by: null
schema_version: 1
related:
- armv7-cross-compile-needs-explicit-mfpu-neon
---

# 预编译库槽位要验符号表，不能只验文件存在

**主张**：仓库内按平台分槽存放的预编译静态库（`libgtrack-linux-arm.a` 等）会**静默漂移**——某次更新只重建了本机槽位，其余槽位装的还是旧版甚至完全不同的库。验收每个槽位用 `nm` 数关键符号（当前 API 的符号应存在、旧库的特征符号应为零），不能只看文件在不在。

**为什么（实测）**：`src/tracker/lib/` 三个平台槽位中，darwin-arm64 和 linux-x86_64 装的是旧 TI gtrack（78 个 `gtrack_` 符号、0 个 `Track*` 符号，而 `gtrack_*` 在仓库已无任何调用方）——mac 之外任何平台构建都会撞上链接期哑弹，这正是 cmake 在 mac 上报 `_TrackInit` 未定义的根因。三个槽位全部同源重建后隐患消除。

**边界**：与 verify-dylib-port-completeness-via-nm-symbols 互补——那条验"新移植的符号进了产物"，本条验"存量槽位里的还是不是那份库"。静态库按需归档，符号缺失在链接期才爆，构建期无信号。

**证据**：session 7c4809cc，三槽位 nm 符号计数对比与同源重建后全链复验。
