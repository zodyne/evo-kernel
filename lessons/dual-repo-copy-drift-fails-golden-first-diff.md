---
id: dual-repo-copy-drift-fails-golden-first-diff
type: lesson
status: candidate
scope: project:ucm221-pointcloud-2-0
domain: debugging
tags: [golden, verification, code-drift, migration, diff]
triggers:
  - golden/回归比对 FAIL，第一反应想查算法实现
  - 同一份源文件在两个仓库/两个目录各存一份拷贝
  - 迁移后跑一致性验证，逐点比对出现超容差偏差
  - 头文件里的配置宏（网格数/阈值/维度）在两处定义
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:da720f38-036f-42ec-820d-ce8538a4fc1f
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [bytes-exact-oracle-gate-for-pipeline-port, make-d-macro-change-skips-rebuild-silently]
---

# 双仓拷贝场景下 golden FAIL：先 diff 两份拷贝，别先怀疑算法

同一份源码在开发仓（embedded/）和集成仓（libucm221/）各存一份拷贝时，逐点比对 FAIL 的**第一嫌疑是拷贝漂移**——某一侧的头文件被单独改过（配置宏、网格数、阈值），两侧编出的不是同一份逻辑。排查顺序：

1. 对全部同源文件跑 `diff -q`（头文件也算，配置宏常住在头文件里）；
2. 发现不一致就还原到已提交状态，重跑验证；
3. 只有拷贝逐字节一致后仍 FAIL，才去查算法。

migrate 类 target 里应固化「N 个源文件逐字节一致」检查作为前置闸门。

**证据**（session da720f38）：`make check` 报 `[FAIL] L1 rho`，`diff embedded/faf.h libucm221/.../faf.h` 发现 embedded 侧被改成 `fafN_GRID 31`（集成仓为 21）；`cp` 还原后 `make check` 全 PASS（L0 位模式 320 行一致、L1 rho max|Δ|=2.385e-07 在容差内）。此前 migrate 输出 `[PASS] 8 个源文件与本目录逐字节一致`。
