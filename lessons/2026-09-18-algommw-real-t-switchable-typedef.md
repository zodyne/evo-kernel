---
id: algommw-real-t-switchable-typedef
type: fact
status: candidate
scope: project:algommw
domain: codebase-map
tags: [algommw, Real_t, typedef, float32, int32]
triggers:
  - "algommw 的 Real_t 到底是 float 还是 int，在哪定义"
  - "移植 algommw 数值代码，要先确认数值类型实际宽度"
  - "对拍发现精度/量化差异，怀疑两侧数值类型不一致（失败信号）"
  - "把 algommw 定点/浮点档位切换到另一档"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af3a-ab1b-7097-91f3-80f1eaca1bbd
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [prefix-own-typedefs-when-embedding-c-module]
---

algommw 全链数值类型走 `Real_t` 条件别名：
`core/include/core/base/types.h:16` 为 `typedef int32_t Real_t;`、
`:18` 为 `typedef float32_t Real_t;`，即**定点/浮点两档按编译条件切换**，
代码主体不直接写死 int32/float32。

为什么：移植或逐级对拍（golden 等价）前必须先确认当前编译档位，
两侧档位不同会产生系统性数值偏差，且这类偏差容易被误判成算法 bug。

边界：本次切片只证实两档别名都存在（rg 命中 types.h:16,18），
「默认生效哪一档」的条件宏名未在命令输出中出现，移植时需打开 types.h:13-20 确认。
证据：会话切片 rg 命令 `rg "Real_t" core/include/core/base/types.h` 输出。
