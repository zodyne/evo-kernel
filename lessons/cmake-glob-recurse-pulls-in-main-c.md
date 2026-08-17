---
id: cmake-glob-recurse-pulls-in-main-c
type: lesson
status: deprecated
scope: global
domain: build-system
tags: [cmake, glob-recurse, static-library, build, porting]
triggers:
  - "用 CMake file(GLOB_RECURSE) 通配收集源文件建库"
  - "库里被意外编进了 main.c / 测试入口 / 示例程序"
  - "移植一个自带 main 的模块进已有 CMake 工程"
  - "链接产物里出现不该有的入口符号，怀疑通配收集太宽"
created: 2026-07-29
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:40a7756a-b82e-42cf-9704-be6eafb35707
last_verified: 2026-07-29
superseded_by: skill:embedded-cross-compilation
schema_version: 1
---
# CMake GLOB_RECURSE 会把目录下全部源文件（含 main.c）编进目标：单独建静态库或显式排除

## 主张

`file(GLOB_RECURSE ...)` 按目录通配收集源文件时，会把该目录树下**所有** `.c` 文件——包括被移植模块自带的 `main.c`、测试入口——全部编进目标。把这类模块合进共享库时，要么给它单独建静态库再整体链接，要么显式排除入口文件，不能指望 GLOB_RECURSE "只收我想要的"。

## 证据

会话中把 false_alarm_filter 模块合入 libucm221 的 `libSPX_ALG.dylib`，修改 CMakeLists.txt 的脚本里自述缺陷：

```
# --- A. 我的缺陷: GLOB_RECURSE 会把 false_alarm_filter/ 连同 main.c 直接编进 .so ---
```

修复方式是让 false_alarm_filter 单独建静态库再合入。修复后构建输出：`-- ✓ 已链接 false_alarm_filter 静态库`、`[ 25%] Built target false_alarm_filter`、`[ 31%] Linking C shared library libSPX_ALG.dylib` 成功，且 `nm -gU build/libSPX_ALG.dylib | grep -E "Faf|Fpga"` 确认只有预期的 9 个模块符号被导出。

## 反例/边界

- 目录树里确定只有库源文件（无 main、无测试）时 GLOB_RECURSE 可用，但新加文件不会被自动察觉（CMake 经典坑），大型工程更推荐显式列出源文件。
- Makefile 语境同理：本 session 的 Makefile 也是让 faf 先 `AR libfalse_alarm_filter.a` 再合入，与 CMake 修复同构。
