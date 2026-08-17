---
id: nvim-lspconfig-in-lazy-lock-but-no-spec-not-in-runtimepath
type: lesson
status: deprecated
scope: global
domain: nvim
tags: [nvim, lazy.nvim, lspconfig, clangd, runtimepath]
triggers:
  - "nvim 里 LSP 全部失效但不报任何错误"
  - "lazy-lock.json 里有某插件但 lua/plugins/ 没有它的 spec"
  - "vim.lsp.config 的默认 root_markers 合并不生效，root_dir 解析为 nil（失败信号）"
  - "诊断 lazy.nvim 下某插件『装了却像没装』"
  - "clangd 挂上但 root: nil / ws: nil（失败信号）"
created: 2026-07-31
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fb5b5-ed73-71ba-8ec2-95256ac3edf8
last_verified: 2026-07-31
superseded_by: skill:nvim-lsp-troubleshooting
schema_version: 1
related: [nvim-headless-verify-lsp-root-and-diagnostics]
---
lazy.nvim 下插件出现在 `lazy-lock.json` ≠ 被加载：它只是作为别的插件的依赖被下载，若 `lua/plugins/` 没有任何 spec 声明它，就不进 runtimepath。nvim-lspconfig 处于此状态时，`vim.lsp.config('clangd', ...)` 合并不到它提供的默认 `root_markers`，于是所有文件的 clangd root 解析为 nil——**全程无报错**，表象是"LSP 静默全灭"。

证据（本session命令输出）：
- `grep -rn "lspconfig" ~/.config/nvim/lua/plugins/` 与 lazy spec 文件均为空，但 `lazy-lock.json` 里有 nvim-lspconfig；
- `nvim --headless ... vim.lsp.get_clients()` 输出 `clangd root: nil ws: nil`，`vim.lsp.config.clangd` 的 `root_markers: nil`；
- 修复动作是写 `/Users/zodyne/.config/nvim/lua/plugins/init.lua`（补 nvim-lspconfig 的 spec），修复后同文件 root 正确解析为项目子目录。

边界：只适用于 lazy.nvim 这类"spec 驱动加载"的插件管理器；排查顺序建议先 `grep lspconfig lua/plugins/` 确认 spec 存在，再怀疑配置内容。
