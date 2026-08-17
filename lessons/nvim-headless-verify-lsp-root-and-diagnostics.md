---
id: nvim-headless-verify-lsp-root-and-diagnostics
type: lesson
status: deprecated
scope: global
domain: tooling
tags: [nvim, lsp, headless, clangd, diagnostics]
triggers:
  - "改了 nvim LSP/lspconfig/clangd 配置，想不开 GUI 验证是否生效"
  - "要在脚本里确认某文件被 LSP 客户端挂上的 root_dir 对不对"
  - "需要拿到某 buffer 的诊断条数来对比改前改后"
  - "nvim --headless 验证 LSP 行为的具体写法"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:6e8c3b5f-c536-4bce-b8f5-937a89375e89
last_verified: 2026-07-31
superseded_by: skill:nvim-lsp-troubleshooting
schema_version: 1
related: [nvim-headless-blocked-by-flatten-nvim]
---

**主张**：验证 nvim LSP 配置（root_dir、诊断数）可以不用开 UI，一条 headless 命令拿量化结果：

```sh
nvim --headless "+e <file>" "+sleep 8" \
  "+lua for _,c in ipairs(vim.lsp.get_clients({bufnr=0})) do \
     print(c.name..' root='..tostring(c.config.root_dir)..' diags='..#vim.diagnostic.get(0)) end" \
  "+qa!"
```

要点：`+sleep 8` 给 LSP 启动和发布诊断留时间（太短会打出 0 假象）；诊断数用 `#vim.diagnostic.get(0)`，客户端 root 用 `c.config.root_dir`。

**实测输出**（UCM221 调 clangd 配置）：改前 `root=.../embedded diags=20`，改后另一文件 `root=.../ucm221-pointcloud-2.0 diags=0`——root_dir 与诊断数一屏对齐，改前改后可对比。

**边界**：macOS 没有 `timeout` 命令（command not found），别拿来包裹这条命令；headless 调用可能打出 flatten.nvim 的 rpc traceback（见 related），本次未阻断输出。
