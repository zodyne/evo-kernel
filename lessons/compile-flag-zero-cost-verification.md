---
id: compile-flag-zero-cost-verification
type: lesson
status: candidate
scope: global
domain: embedded-c
tags: [c, ifdef, compile-flag, nm, verification, embedded]
triggers:
  - "给 C/嵌入式代码加 #ifdef 编译期开关"
  - "想证明开关关闭时零开销（无符号、无 bss、不增大 .o）"
  - "用 nm / size 验证编译开关是否真的生效"
  - "可选功能默认关闭，需验证默认构建产物里确实不含它"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:40a7756a-b82e-42cf-9704-be6eafb35707
last_verified: 2026-07-29
superseded_by: null
schema_version: 1
---
# 编译期开关的"零成本"验证三件套：nm 符号随开关出现/消失 + .o 大小 + bss 字节数

## 主张

给嵌入式 C 代码加 `#ifdef` 可选功能（默认关）时，"默认路径零开销"不能只靠读代码判断，要用三件套实测：① `nm` 查功能专属符号随开关出现/消失；② 对比两种构建的 `.o` 大小；③ 查 `__bss/__common` 静态未初始化数据字节数。三项都符合预期才算开关真正生效且默认零成本。

## 证据

给 `SP_GeneratePiontCloud` 加 `SP_ENABLE_ENERGY_NMS` 开关后实测输出：

```
[默认(关)] 退出码=0  本函数告警=0  bestIdx符号=0  .o大小=20216
[-DSP_ENABLE_ENERGY_NMS=1] 退出码=0  本函数告警=0  bestIdx符号=1  .o大小=21984
[默认(关)] 静态未初始化数据(__bss/__common) = 0 字节
[-DSP_ENABLE_ENERGY_NMS=1] 静态未初始化数据(__bss/__common) = 0 字节
```

`bestIdx` 静态表（`static int bestIdx[RANGE][VELOCITY]` 量级）在默认构建中符号数为 0、.o 小 1768 字节，两种构建 bss 均为 0——证明默认路径既没有代码也没有静态 RAM 开销。

## 反例/边界

- macOS 的 `size -m` 对单 `.o` 可能报 "can't be opened"，符号法（nm）更稳， bss 用 `size -m` 看段摘要或 `nm -m | grep __bss`。
- 编译器可能在 -O2/-O3 下内联掉小函数使符号消失，符号消失≠一定被开关裁掉；结合 .o 大小差一起判断。
