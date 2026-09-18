---
id: nvim-lspconfig-lazy-false-root-markers
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, lazy-nvim, nvim-lspconfig, root-markers, nvchad, lsp]
triggers:
  - "lazy.nvim 里把 nvim-lspconfig 配成懒加载（event / cmd / keys 触发）"
  - "LSP 只在单文件内工作，跨文件跳转/引用失效（失败信号）"
  - "LSP 报单文件模式 / root_dir = nil，或项目根识别不出来（失败信号）"
  - "各 server 的默认 root_markers 没被合并、nvim 不按工程根启动 LSP"
  - "排查 nvim 配置里 LSP 整体退化，怀疑插件加载时机/顺序"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a7aa-e5eb-725c-a75a-f980f1444774
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [nvchad-mappings-override-lazy-keys-after-schedule, debug-nvim-lsp-via-live-server-socket]
---

# lazy.nvim 下懒加载 nvim-lspconfig 会让 root_markers 合并失败，LSP 整体退化成单文件模式

**主张**：在 lazy.nvim 里把 `nvim-lspconfig` 当普通插件懒加载，会导致各 server 默认的 `root_markers` 合并不到，`root_dir = nil`，**所有** LSP 退化为单文件模式；修复方式是给 `nvim-lspconfig` 显式写 `lazy = false`（让它先于 LSP 配置加载），而不是逐个 server 去补 `root_dir`。

**证据（切片 `01a0a7aa-e5eb-725c-a75a-f980f1444774`，逐字引用）**：

1. 修复提交自述（命令 `cd /Users/zodyne/Dev/dotfiles && git log --format='%h %cI %s' -6 -- config/nvim/lua/plugins/init.lua`）：
   ```
   b8a8e60 2026-09-04T13:11:15+08:00 fix(nvim): nvim-lspconfig 显式 lazy=false，修复 root_markers 合并不到导致 LSP 单文件模式退化
   ```
2. 同一轮取证里，审计会话（session3）的现象记录（命令 `rg -o -- '.{160}NVIM.{160}' <session3 jsonl>`）：
   ```
   合并不到各 server 的默认 root_markers，
       -- 所有 LSP 退化为单文件模式 (root_dir=nil
   ```

环境（同切片首条 user）：nvim 0.12.4（Homebrew）、lazy.nvim + NvChad、配置真身 `/Users/zodyne/Dev/dotfiles/config/nvim`。

**为什么值得记**：症状是"LSP 全都坏"，很容易被误判为 mason / server 没装 / 版本不兼容，从而往"装 server、改 server 配置"方向返工；真实原因是加载时机——插件的 `lazy` 决定 `root_markers` 默认值合不进来的那一刻，配置已经定型了。所以判据是"所有 server 一起坏 + root_dir=nil"，修复动作只有一行 `lazy = false`。

**边界 / 证据强度（如实标注）**：
- `verified_by: human`：切片里只有「修复提交的自述 + 审计会话里的现象记录」，**本会话没有现场复现** `root_dir=nil` 的 nvim 命令（切片里没有真正执行 `nvim --headless +checkhealth`，该字样只出现在被 grep 的历史会话文本里）。
- 要升级成 `command`：需要一条能独立复现的探针，例如把该插件改回懒加载后读某个 client 的 `root_dir` 是否为 nil（本切片未做）。
- 适用面：lazy.nvim（含 NvChad 基础配置）；不用 lazy.nvim 的配置不涉及此坑。
