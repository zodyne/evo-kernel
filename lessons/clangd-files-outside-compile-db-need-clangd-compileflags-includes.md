---
id: clangd-files-outside-compile-db-need-clangd-compileflags-includes
type: lesson
status: deprecated
scope: global
domain: tooling
tags: [clangd, compile_commands, dot-clangd, include-path, c, nvim]
triggers:
  - "clangd 报 pp_file_not_found / 'xxx.h' file not found，但头文件明明在仓库里"
  - "compile_commands.json 存在却只覆盖了部分源文件（如只 build 了 core/，platform/、host/ 不在内）"
  - "嵌入式项目里 BSP/HAL 头文件搜索路径不想逐个文件手写 -I"
  - "想让不在编译数据库里的文件也有正常的 clangd 跳转/诊断"
created: 2026-08-10
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019febc9-0500-7400-b95e-bb526bd26016
last_verified: 2026-08-10
superseded_by: null
schema_version: 1
related: [clangd-per-file-upward-cdb-shadows-nested, clangd-subproject-missing-compile-commands-failed-to-find, clangd-check-headless-repro-editor-diagnostics]
---

**主张**：compile_commands.json 只覆盖部分源文件时，未覆盖的文件 clangd 拿不到任何 `-I` 头文件搜索路径，报 `[pp_file_not_found] 'xxx.h' file not found`。修法：仓库根放 `.clangd`，用 `CompileFlags: Add: [-I<dir>, ...]` 把 include 目录补上——`.clangd` 对没有 DB entry 的文件兜底生效，诊断随之清零。可以把"扫描仓库 include 目录 + 生成 .clangd"挂进 lspconfig 自动化（文件已存在则不覆盖，留人工接管口）。

**实测**（algommw，C/FreeRTOS 单仓）：`build/compile_commands.json` 有 56 条 entry 但 `platform/freertos/main.c` 报 `'bsp/bsp.h' file not found`（2 errors，exit 3）；生成根 `.clangd`（4 个 include 目录，头部注释注明"给不在 compile_commands.json 内的文件补头文件搜索路径"）后，同命令复测 main.c/bsp.c/hal_adc_impl.c 等全部 `0 errors`，nvim headless `DIAG_COUNT=0`；另起 `/tmp` 合成工程（仿 BSP/CMSIS 目录结构）复测生成器，同样 `DIAG_COUNT=0`。

**边界**：与已有两条互补——`clangd-per-file-upward-cdb-shadows-nested` 讲"多份 DB 互相遮蔽/指错"，`clangd-subproject-missing-compile-commands-failed-to-find` 讲"子项目根本没有 DB"，本条讲"DB 在但覆盖不全"；若文件其实在 DB 里却仍缺 -I，先查 DB entry 本身的 flags 再考虑 .clangd。
