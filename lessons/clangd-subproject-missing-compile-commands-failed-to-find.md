---
id: clangd-subproject-missing-compile-commands-failed-to-find
type: lesson
status: candidate
scope: global
domain: clangd
tags: [clangd, compile_commands, c, monorepo, lsp]
triggers:
  - "单仓多 C 子项目，某个子目录的文件 clangd 不工作"
  - "clangd --check 报 Failed to find compilation database（失败信号）"
  - "子项目有自己的构建目录但从来没有生成过 compile_commands.json"
  - "给嵌入式/Makefile 项目补 compilation database（make compdb 一类 target）"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fb5b5-ed73-71ba-8ec2-95256ac3edf8
last_verified: 2026-07-31
superseded_by: null
schema_version: 1
related: [clangd-per-file-upward-cdb-shadows-nested, nvim-headless-verify-lsp-root-and-diagnostics]
---
clangd 对每个源文件**向上查找最近的 compile_commands.json**；单仓多子项目时，若某子项目目录树里从来没有生成过 compilation database，该子项目的文件报 `Failed to find compilation database`，LSP 对该子项目整体失效。修法是给子项目各自生成 compile_commands.json（本例用 `embedded/Makefile` 里已有的 `make compdb` target），生成后 clangd 立即按子项目根正确解析。

证据（本session命令输出）：
- 修复前：`clangd --check=embedded/faf.c` → `Failed to find compilation database for .../embedded/faf.c`（同命令对 `libucm221/src/.../ifAlg.c` 则正常 Loaded）；
- `cd embedded && make compdb` 生成 `compile_commands.json`；
- 修复后：`clangd --check=embedded/faf.c` → `Loaded compilation database`；`nvim --headless` 显示 `libucm221 -> clangd | root: .../libucm221`，`embedded -> clangd | root: .../embedded` 两子项目各自挂根成功。

边界：与 `clangd-per-file-upward-cdb-shadows-nested` 互补——那条讲"多个 database 互相遮蔽/指错"，本条讲"子项目根本没有 database"。
