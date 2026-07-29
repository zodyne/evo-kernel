---
id: prefix-own-typedefs-when-embedding-c-module
type: lesson
status: validated
scope: global
domain: c-integration
tags: [c, typedef, naming-collision, porting, build, integration]
triggers:
  - "把一个自包含的 C 模块移植/搬运进一个已有自己类型定义的大仓库"
  - "集成时报 conflicting types / redefinition of typedef 'float32_t'"
  - "宿主仓库经 vendor 头（如 NE10_types.h / cmsis / 各类 dsp 库）已定义 float32_t/float64_t"
  - "两套同名 typedef 字宽/修饰不同，导致隐式裁剪或链接符号二义（失败信号）"
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:fb616292-c015-42e4-9987-16229ad221f3
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
---
# 移植 C 模块进大仓库时，给自有 typedef 加项目前缀避免重定义冲突

**主张**：把一个自包含的 C 模块搬进已自带类型定义的宿主仓库时，模块自己 `typedef float float32_t;` 这类通用名 typedef 会与宿主**重定义冲突**（宿主常经 vendor 头如 `NE10_types.h`、CMSIS、各 DSP 库先定义了同名类型）。修法：给模块自有 typedef 加项目前缀（`float32_t → FafFloat32_t`、`float64_t → FafFloat64_t`）后全文替换，保持模块自洽又不撞宿主命名空间。

**根因**：`float32_t`/`float64_t` 是 C 生态里极常见的通用 typedef 名，多个库各自定义；C11 之前 typedef 重定义要求完全一致，字宽/修饰稍异即编译失败，即便一致也会在维护上造成"同名不同源"的混淆。

**修法**：选一个项目短前缀（如 Faf = False Alarm Filter），统一改名头文件与实现；用 `sed`/`perl -pi -e 's/\bfloat32_t\b/FafFloat32_t/g'` 批量替换全部源文件，再重编。

**反例/边界**：若模块本就用 `<stdint.h>` 的 `uint32_t` 等标准名，无需改；专指模块自定义的、与宿主可能撞名的 typedef。

**证据**（session fb616292）：
- 冲突源：`grep -rn "typedef.*float32_t" include src` → `include/common/neon/NE10_types.h:76:typedef float ne10_float32_t;`，嵌入式侧另有 `typedef float float32_t;`。
- 修复：`perl -pi -e 's/\bfloat32_t\b/FafFloat32_t/g; s/\bfloat64_t\b/FafFloat64_t/g' faf.h faf.c fpga_frame.* faf_pyapi.c test/main_golden.c`。
- 验证：libucm221 内 `make` 成功、golden 复跑 `[PASS]`、`nm -gU libSPX_ALG.dylib | grep Faf` 导出 `_vFafComputeFrameFeatures` 等符号。
