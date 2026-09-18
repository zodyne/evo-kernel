---
id: ctypes-argtypes-table-drift-silent-cint-restype
type: lesson
status: candidate
scope: project:algommw
domain: ctypes-bridge
tags: [algommw, ctypes, argtypes, restype, native-binding, drift]
triggers:
  - "给 ctypes 绑定新增/移植函数，要写 argtypes/restype 驱动表"
  - "启动自检表已建，担心漏设某个绑定的 argtypes/restype"
  - "ctypes 调用返回值怪异但不报错，怀疑 restype 缺省 c_int"
  - "审查 native binding 层参数声明与真实 C 签名是否一致"
  - "同一份绑定函数表在多处手工维护，怀疑已漂移"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af3a-abe4-7097-91f3-80f609ecb9bd
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [ctypes-shared-static-workspace-thread-lock]
---

algommw 的 ctypes 绑定函数表曾两处手工各一份并已漂移：Spectra/SnapCube 漏设
argtypes，仅因 restype 缺省 c_int 恰好装得下才没爆——即绑定表漂移可以静默存活，
不崩、不报错，靠运行异常发现不了；防漂移手段是集中为单一驱动表 + 启动自检
（`_fn.argtypes = [...]` 逐项装配），而不是依赖报错暴露。

为什么：restype 缺省 c_int 对指针/整型返回值有偶然容错，漏设 argtypes 不会立刻
出错，等参数类型实际不匹配时才以难排查的方式显现；这套链要移植 C++，绑定面还会
扩大，表越写越多，漂移面随之扩大。

边界：本条只断言「漏设 argtypes 被 c_int 缺省 restype 掩盖、需唯一驱动表+自检」，
不断言自检表本身已逐项覆盖全部调用面（那需要逐项对账证据，本切片没有）。

证据：`grep -n "argtypes|restype" python/core_bind/native.py` 命中源码注释原文：
"此前两处手工各一份,已漂移 —— Spectra/SnapCube 漏设 argtypes，只是 restype 默认
c_int 恰好能装下才没爆。" 及集中装配循环 `41: _fn.argtypes = []`。
