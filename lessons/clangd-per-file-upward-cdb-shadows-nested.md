---
id: clangd-per-file-upward-cdb-shadows-nested
type: lesson
status: candidate
scope: global
domain: tooling
tags: [clangd, compile_commands, lsp, nvim, c]
triggers:
  - "clangd/nvim 里 C 项目跳转补全用错编译参数、满屏误报诊断"
  - "仓库里有多个 compile_commands.json（子目录 make compdb 生成的）"
  - "想用 .clangd 把某子目录重定向到另一个编译数据库"
  - "改了 nvim root_dir/lspconfig 但 clangd 用的 flags 还是不对（失败信号）"
  - "clangd --check 显示 Loaded compilation database from 错误路径（失败信号）"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:6e8c3b5f-c536-4bce-b8f5-937a89375e89
last_verified: 2026-07-31
superseded_by: null
schema_version: 1
---

**主张**：clangd 的 compile_commands.json 是**逐文件、从源文件逐级向上**找的，与编辑器侧的 nvim `root_dir` 无关；子目录里的编译数据库会**遮蔽**仓库根/别处真正想用的那份。

**案例**（UCM221）：`embedded/sim/sim_pipeline.c` 向上撞到 `embedded/compile_commands.json`（`make compdb` 生成的旧 flags），而真正该用的是 `libucm221/build/compile_commands.json`——nvim 里 20 条误报诊断。改 lspconfig 的 root_dir 无效。

**修复**（实测生效）：仓库根放一个 `.clangd`：

```yaml
If:
  PathMatch: embedded/sim/.*
CompileFlags:
  CompilationDatabase: libucm221/build
```

两个踩过的坑（前两次写法都未生效，`clangd --check` 仍显示加载 embedded/ 的 CDB）：① `CompilationDatabase:` 必须放在 `CompileFlags:` 之下，不能作为 fragment 顶层键；② PathMatch 用 `embedded/sim/.*`，不要带 `.*/` 前缀。

**验证方法**：`clangd --check=<file> 2>&1 | grep "Loaded compilation database"`——修好后 sim_pipeline.c 显示从 `libucm221/build` 加载；nvim headless 复测诊断 20 → 0（faf.c root=仓库根 diags=0）。

**边界**：`.clangd` 是项目级配置，放仓库根；用户级在 `~/Library/Preferences/clangd/config.yaml`（macOS）。
