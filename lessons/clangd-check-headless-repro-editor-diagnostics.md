---
id: clangd-check-headless-repro-editor-diagnostics
type: lesson
status: candidate
scope: global
domain: tooling
tags: [clangd, lsp, nvim, c, diagnostics, headless]
triggers:
  - "nvim/编辑器里 clangd 报诊断，想在终端里复现而不是开 UI"
  - "改了 clangd/lspconfig 配置，要对比改前改后每个文件的 errors 数"
  - "想确认 clangd 对某文件实际加载了哪份 compile_commands.json"
  - "把 LSP 诊断检查塞进脚本/批量循环（失败信号：只能靠肉眼开编辑器确认）"
created: 2026-08-10
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019febc9-0500-7400-b95e-bb526bd26016
last_verified: 2026-08-10
superseded_by: null
schema_version: 1
related: [nvim-headless-verify-lsp-root-and-diagnostics, clangd-per-file-upward-cdb-shadows-nested, clangd-check-tweak-fail-noise-not-diagnostics]
---

**主张**：编辑器里的 clangd 诊断可以在终端直接复现与量化对比——对嫌疑文件跑 `clangd --check=<file>`（用编辑器同一个 clangd 二进制，如 mason 装的那个），它输出实际加载的 compile DB 路径（`Loaded compilation database from ...`）和逐条诊断，结尾 `All checks completed, N errors`，有诊断时 exit≠0。包一层 for 循环就能批量跑多个文件，改前改后同命令对比 errors 数，全程不用开 nvim。

**实测**（algommw 修 `bsp/bsp.h` file not found）：
- 改前：`clangd --check=platform/freertos/main.c` → `2 errors`，exit 3；
- 改后：`for f in main.c bsp.c hal_adc_impl.c ...` 循环跑 → 全部 `All checks completed, 0 errors`。

**边界**：输出里混有 tweak 失败的 E[ 噪音行，判真实诊断要再过滤（见 related `clangd-check-tweak-fail-noise-not-diagnostics`）；与 `nvim-headless-verify-lsp-root-and-diagnostics` 互补——那条验证 nvim 客户端侧（root_dir、buffer 诊断数），本条验证 clangd 服务端单文件诊断，不依赖 LSP 客户端启动时序。
