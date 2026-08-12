---
id: macos-no-clock-boottime
type: lesson
status: candidate
scope: global
domain: porting
tags: [macos, clock_gettime, porting, c, embedded]
triggers:
  - "把 Linux/嵌入式 C 代码移植到 macOS 编译"
  - "编译报 use of undeclared identifier 'CLOCK_BOOTTIME'"
  - "clock_gettime 的时钟 id 跨平台写法"
  - "macOS 上编译厂商嵌入式代码出现 Linux 专属标识符未声明"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:40a7756a-b82e-42cf-9704-be6eafb35707
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
related: [macos-no-timeout-command]
---
# macOS 没有 CLOCK_BOOTTIME：移植 Linux/嵌入式 C 代码需换 CLOCK_MONOTONIC 或条件编译

## 主张

Linux/嵌入式厂商代码里常见的 `CLOCK_BOOTTIME` 在 macOS 上不存在（编译期直接报未声明）。移植到 macOS 时把单调启动时钟换成 `CLOCK_MONOTONIC`，或用 `#ifdef CLOCK_BOOTTIME` 条件编译保留原路径。

## 证据

libucm221 在 macOS 上编译时报：

```
systemTime.c:8:19: error: use of undeclared identifier 'CLOCK_BOOTTIME'; did you mean '_CLOCK_REALTIME'?
```

`src/signalProcess/systemTime.c` 的 `getSystemBootMicros()` 用 `clock_gettime(CLOCK_BOOTTIME, ...)`。修改该文件（写文件清单含 systemTime.c）后，同一 CMake 构建后续全部通过（`Built target SPX_ALG` 等）。

## 反例/边界

- `CLOCK_MONOTONIC` 与 `CLOCK_BOOTTIME` 语义差异：Linux 上 BOOTTIME 包含 suspend 时间，MONOTONIC 不含；macOS 的 CLOCK_MONOTONIC 不含 suspend。若算法依赖"suspend 期间也计时"，换宏会引入行为差异，需在移植说明里注明。
- 同属"macOS 缺 GNU/Linux 设施"一族的还有 `timeout` 命令缺失（见 related），排查移植问题时按一族想。
