---
id: clangd-moved-source-stale-compile-db
type: lesson
status: candidate
scope: global
domain: tooling
tags: [clangd, compile-commands, lsp, interpolation, silent-fallback]
triggers:
  - "源码目录与构建目录分离（migrate/拷贝后编译）时 clangd 补全跳转全废（失败信号）"
  - "clangd 找到 compile_commands.json 但头文件解析失败"
  - "配置 .clangd 的 CompilationDatabase 指向"
created: 2026-08-03
evidence: {helpful: 0, harmful: 0}
verified_by: none
source: session:2e76dde5
last_verified: 2026-08-03
superseded_by: null
schema_version: 1
---
# 源文件被拷到别处编译时，clangd 会拿错误编译数据库"插值"，AST 静默塌掉

**主张**：clangd 从源文件所在目录逐级向上找第一个 `compile_commands.json`，且**按绝对路径精确匹配**文件名；匹配不上时**静默挑一条"最像的"记录插值参数**。源码靠 `make migrate` 逐字节拷到他处编译的项目（如 embedded/sim → libucm221），clangd 会拿旧数据库猜参数——13 个 `-I` 一个没有，头文件解析失败，跳转补全全废且无报错。修法：在该子树放 `.clangd`，用 `CompilationDatabase:` + `PathMatch` 指向真实构建产出的数据库，参数由真实构建维护、不手抄。

**为什么**：这是"配置未生效但看似在工作"的静默失效——clangd 不报错，只是智能感知缓慢劣化。验证方式：`clangd --check=<file> 2>&1 | grep -E "Loaded comp|All checks"`。

**边界**：前提是真实构建数据库已生成（`cmake -S ... -B build` 跑过）；数据库缺失时 clangd 仍退回向上搜索老路。

**证据**：session 2e76dde5，embedded/sim 子树 `.clangd` 改指 libucm221/build 后 `clangd --check` 通过；仓库 .clangd 文件头注释有完整机制说明。
