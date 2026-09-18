---
id: nvchad-sidekick-terminal-filetypes
type: fact
status: validated
scope: global
domain: nvim
tags: [nvim, nvchad, sidekick, terminal, filetype, autocmd, keymaps]
triggers:
  - "给 nvim 的终端 buffer（NvChad 自带终端 / sidekick CLI 终端）加 FileType autocmd 或 buffer-local 键位"
  - "`pattern = \"terminal\"` 的 autocmd 在终端里不触发（失败信号：以为终端都叫 terminal）"
  - "要区分 NvChad :terminal 与 sidekick 起的 CLI 终端，写只命中其中一类的映射"
  - "排查 nvim 终端里 jk/j/k 这类键位到底有没有装上（用 maparg / nvim_get_keymap 看不到预期映射）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b29d-0cb6-7097-91f3-80f8d5ba1119
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [sidekick-pi-cli-cmd-defined-in-plugin-sk-dir]
---

**主张**：本机 nvim 里两类终端 buffer 的 `filetype` **都不是** `terminal`：

- NvChad 自带终端（lazy 包 `ui`）：`vim.bo[opts.buf].ft = "NvTerm_" .. opts.pos…`，即 `NvTerm_<位置>`（会话里的 autocmd 用的是 `pattern = "NvTerm*"`）；
- sidekick 起的 CLI 终端（pi / claude 等）：`ft=sidekick_terminal`（探针实测 `1) 假 CLI 终端 (ft=sidekick_terminal)`、`name=lin500.txt ft=sidekick_terminal mode=t lines=39`）。

所以给终端加 FileType autocmd / buffer-local 键位时，只匹配 `terminal` 或只匹配其中一类，都会静默漏掉另一类——映射"看起来装了"但目标 buffer 上没有。

**证据**（会话 01a0b29d 切片，命令 ↔ 结果）：
- `rg -n "NvTerm" ~/.local/share/nvim/lazy/*/lua --glob '*.lua' …` → `/Users/zodyne/.local/share/nvim/lazy/ui/lua/nvchad/term/init.lua:67:  vim.bo[opts.buf].ft = "NvTerm_" .. opts.pos:gsub("`。
- `nvim --server … --remote-expr` 探针跑 lua：`== 1) 假 CLI 终端 (ft=sidekick_terminal)：jk 应送进 job ==`；以及 `name=lin500.txt ft=sidekick_terminal mode=t lines=39 sha=…`（`less` 起在 sidekick 终端里）。
- buffer-local 映射的探针（确认映射真的落在终端 buffer 上，而不是全局）：`buf 5 pi  n 模式 j/k: [j k] desc=[CLI: 下滚 / CLI: 上滚]`。

**边界/反例**：`NvTerm_<pos>` 的后缀随打开位置变化（float/bottom/… 未在切片里逐一验证），所以写 autocmd 用前缀通配 `NvTerm*`；sidekick 的 `sidekick_terminal` 是会话中实测值，换 sidekick 版本或换别的 CLI 插件（snacks 等）可能另有 ft，动手前先用 `vim.bo.filetype` 实测一遍，别照抄。
