---
id: clang-fdump-record-layouts-verifies-struct-layout
type: lesson
status: validated
scope: global
domain: c-abi
tags: [clang, struct-layout, c99, ffi, abi]
triggers:
  - "验证 C 结构体 sizeof/对齐/字段偏移假设时"
  - "做 C 结构体布局迁移/ABI 核对/FFI 边界对齐，不想手推 padding"
  - "跨平台判断 struct 是否字节级一致、逐位相同"
  - "手推结构体大小结果与编译器/平台实际不符（失败信号：sizeof 对不上 golden）"
  - "给 C 结构体布局做确定性验证而非依赖 ABI 常识"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0af3a-aa91-7097-91f3-80ed3e90840c
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

一句话主张：验证 C 结构体的 sizeof/对齐/字段偏移，用 clang 前端 dump record layout，而不是手推 padding 或依赖 ABI 常识，结果确定且可直接当证据引用。

为什么：algommw core 迁移（C99 mmWave 雷达链）前，需先确认结构体（如 xCOMPLEX_16）的大小与对齐，作为后续 FFI / 逐位 golden 对拍的前提。手推 padding 易漏对齐规则；clang 直接 dump 出权威布局，且输出自带 `[sizeof=N, align=M]`，可直接对账。

命令（切片实测）：
    clang -x c -std=c99 -I core/include -fsyntax-only -Xclang -fdump-record-layouts /dev/stdin
输出示例：
    0 | struct xCOMPLEX_16 [sizeof=4, align=2]  (两个 int16_t 字段 sI/sQ)

反例/边界：`-Xclang -fdump-record-layouts` 是 clang 前端专用（经 -Xclang 透传）；gcc 等其他前端是否有等价 dump 开关本会话未验证，换编译器需另行确认。dump 只给布局，不校验语义与字节序——字节级一致性仍要靠逐位 golden 对拍兜底。

静默空输出的坑（2026-09-18 补）：plain `-Xclang -fdump-record-layouts`（不带 `-complete`）只打印**在 codegen 中真正被实例化/使用过**的记录——TU 里只定义、从未使用的 struct 得到**零输出**，不能据此判断「布局没问题/无布局」。要 dump 某结构体必须真的用到它（加一行 `struct s v;`）并编译到 `-c -o /dev/null`（`-fsyntax-only` 下未使用同样零输出）。只想核对头文件里的定义而不构造使用点时，改用 `-Xclang -fdump-record-layouts-complete`（列出全部已定义记录），但它的输出**以编译器内置记录开头**（如 `struct __NSConstantString_tag [sizeof=32, align=8]`），容易看漏目标 struct，别用 `head` 截断。

证据：session:01a0af3a-aa91-7097-91f3-80ed3e90840c 中多轮 record-layout dump 均返回 sizeof/align（xCOMPLEX_16=4/align2、xCOMPLEX_F=8 等），结论喂给迁移报告。
