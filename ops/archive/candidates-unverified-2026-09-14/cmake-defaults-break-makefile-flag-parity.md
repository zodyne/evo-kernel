---
id: cmake-defaults-break-makefile-flag-parity
type: lesson
status: candidate
scope: global
domain: build-systems
tags: [cmake, makefile, flag-parity, c-standard, ndebug, ffp-contract]
triggers:
  - "给已有 Makefile 项目补 CMake 构建（或反之）"
  - "两套构建系统产物需要逐字节一致/数值可比"
  - "CMake 默认 gnu11 或 Release -DNDEBUG 引入语义差异（失败信号）"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:7b0f5574
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
---
# 与 Makefile 对齐的 CMake 必须按死两个默认：CMAKE_C_EXTENSIONS OFF、不设默认 build type

**主张**：要求 CMake 与既有 Makefile 编译参数逐字相同时：① `set(CMAKE_C_EXTENSIONS OFF)`——否则 `CMAKE_C_STANDARD 11` 给的是 `-std=gnu11` 而非 `-std=c11`，GNU 扩展会让"主机上编得过"掩盖目标工具链问题；② **不设 `CMAKE_BUILD_TYPE` 默认值**——Release 会注入 `-O3 -DNDEBUG`，`-O3` 可被后续 `-O2` 覆盖（最后一个生效）但 `-DNDEBUG` 不会，是实打实的语义差异。涉及数值 golden 比对时 `-ffp-contract=off` 不可缺（FMA 改变舍入路径）。

**为什么**："能编过"不等于等价——验收方式是两条路径产物**逐字节一致** + 同名验收目标全 PASS，而不是 CMake 跑通就算数。

**边界**：纯 CMake 项目无对齐需求时不必；换档位后 golden 不通过要先在两条构建路径上复现再归因（golden 冻结在 n_grid=21，31 档 check 失败是预期，不是 CMake 回归）。

**证据**：session 7b0f5574，faf 模块 CMake/Makefile 双路 `c_points.csv`/`c_frames.csv` 逐字节一致，check/pycheck/facade/bench 四目标等价通过。
