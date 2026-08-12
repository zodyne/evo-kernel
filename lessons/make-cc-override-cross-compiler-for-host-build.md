---
id: make-cc-override-cross-compiler-for-host-build
type: lesson
status: candidate
scope: global
domain: build-verification
tags: [makefile, cross-compile, cc-override, host-build]
triggers:
  - "交叉编译工程想在开发机（macOS/Linux）本机快速验证构建"
  - "Makefile 里写死了 arm-none-eabi-gcc 等交叉编译器，本机没有"
  - "make CC=cc 命令行覆盖编译器变量（命令）"
  - "不想为本机验证去改 Makefile 或加 configure 分支"
  - "嵌入式工程移植进度核查，需要快速确认代码在本机能编过"
created: 2026-07-30
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fb0ee-1906-76a9-a190-ba6c6e81dc29
last_verified: 2026-07-30
superseded_by: null
schema_version: 1
related: [native-posix-freertos-preview-before-mcu]
---
交叉编译工程的 Makefile 若用 `CC ?= ...` 或普通变量定义编译器，**`make CC=cc` 命令行变量覆盖优先级最高**，无需改任何文件即可换成本机编译器做构建验证。

**为什么**：UCM221 libucm221 移植核查会话中，Makefile 面向交叉编译，直接用 `make CC=cc` 在本机完成构建（"构建完成"、libSPX_ALG.dylib 生成），并反复用它做"改一处→重编→nm 验证"的快速反馈环。命令行变量是 GNU make 覆盖优先级最高的来源（高于文件内赋值，除非用了 override 指令），是零侵入的本机验证手段。

**边界**：若 Makefile 用 `override CC :=` 写死或在规则里硬编码编译器路径，此法失效，需改文件或用 `-e` 环境变量覆盖；交叉专属编译选项（-mcpu 等）在本机编译器下可能报错，需另行处理。

**证据**：会话 019fb0ee 中 15+ 次 `make CC=cc` 构建命令，最终产物 dylib 生成且符号核查通过。
