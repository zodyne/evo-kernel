---
id: algommw-plus-type-widths-for-offsetof
type: fact
status: candidate
scope: project:algommw-plus
domain: codebase-map
tags: [algommw-plus, types, offsetof, enum, typedef]
triggers:
  - "给 algommw-plus 生成/核对 offsetof 字段表，需要每个字段类型的字节宽度"
  - "在 algommw-plus 里看到 Deg_t / Rad_t / Log2_t / Db_t，想知道它是裸 float 别名还是 struct 包装"
  - "C++17 移植 / FFI / ctypes 镜像要对齐 algommw-plus 的标量宽度与枚举底层类型"
  - "手推字段偏移时把单位标签当裸 float、把枚举当编译器默认 int（失败信号：偏移或镜像对不上）"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0bc91-2069-7002-b369-2444691b0f3f
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [algommw-plus-core-headers-ifndef-guard-convention, algommw-real-t-switchable-typedef, ctypes-mirror-offsetof-full-compare]
---

# algommw-plus 标量/单位类型宽度与枚举底层类型（offsetof 表前置事实）

**主张**：按 `ChainCfg_t` 字段清单会话的报告，`/Users/zodyne/Dev/algommw-plus` 里
`Real_t` = `float`(4B)；`Deg_t` / `Rad_t` / `Log2_t` / `Db_t` 都写作 `struct{Real_t xV}`(4B)，
即单位/对数/分贝是**4 字节 struct 包装**而不是裸 `float` 别名；`ComplexF_t` = `{Real_t xRe, xIm}`(8B)；
枚举**统一显式指定底层类型 `: int32_t`**(4B)。

**为什么**：生成 offsetof 字段表或做 ctypes/FFI 镜像时，字段宽度决定偏移与 padding。
两条容易踩的直觉假设在这里都不成立：① `Deg_t` 这类单位类型不是 `float` 别名，写成 `float` 虽然本平台同为 4B，
但类型层语义不同；② 枚举宽度不是"编译器默认 int"，而是显式钉死 `int32_t`——跨编译器/平台镜像时不能靠默认值对齐。

**边界 / 反例**：
- 本条的来源是会话末条 assistant 的汇总报告，**该切片 `命令 ↔ 结果` 为 0 条**、无编译/命令佐证，
  故 `verified_by: human`。入库前或正式使用前应用 `rg` 打开 `core/include/` 下对应头文件复核，
  并确认枚举底层类型是否受编译条件（宏）影响。
- 只覆盖标量/单位/复数与枚举；`ChainCfg_t` 各嵌套子结构体的字段与数组长度不在本条主张范围内。
- 与 `algommw-real-t-switchable-typedef` 是**不同仓库**：`algommw`（无 plus）的 `Real_t` 是定点/浮点两档条件别名，
  本条报告的是 `algommw-plus` 为 `float`。两者不要互相套用，跨仓库移植时需各自确认。

**证据**：session `01a0bc91-2069-7002-b369-2444691b0f3f` 切片末条 assistant（首条 user 要求只读收集
`ChainCfg_t` 及嵌套子结构体精确字段清单用于 offsetof 表）：
> 以下按声明顺序，格式 `字段  类型`；数组标注长度。**标量别名**：Real_t=float(4B)；Deg_t/Rad_t/Log2_t/Db_t=struct{Real_t xV}(4B)；ComplexF_t={Real_t xRe,xIm}(8B)；uint8_t/uint16_t/uint32_t/int32_t。**枚举底层类型**：均 `: int32_t`(4B)——…
