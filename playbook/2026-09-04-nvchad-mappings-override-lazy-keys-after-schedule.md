---
id: nvchad-mappings-override-lazy-keys-after-schedule
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, NvChad, lazy.nvim, mappings, 键位覆盖, vim.schedule]
triggers:
  - lazy.nvim 插件的 keys 懒加载绑定被 nvchad.mappings 覆盖
  - vim-tmux-navigator 的 C-h/j/k/l 在 NvChad 下失效
  - init.lua 用 vim.schedule 延后加载 mappings 后键位被后设的赢
  - 想保留 lazy-key 插件的绑定，不知道要不要在 nvchad.mappings 之后重新绑定
  - 用 nvim --headless + maparg 查某个键位到底是谁的映射
created: 2026-09-04
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: capture:capture-2026-09-04-03-22-39-900-vufn
last_verified: 2026-09-04
superseded_by: null
schema_version: 1
related: []
---

# NvChad/lazy.nvim：lazy 的 keys 绑定会被随后加载的 nvchad.mappings 覆盖

NvChad/lazy.nvim 场景下，init.lua 常见写法是 lazy.setup(...) 同步执行后，用 vim.schedule(function() require('mappings') end) 延后加载用户/nvchad 的按键映射。如果某个 lazy.nvim 插件靠 keys 字段抢占键位做懒加载（如 vim-tmux-navigator 的 C-h/j/k/l），会被随后加载的 nvchad.mappings 默认绑定覆盖——同一个 lhs 后设的赢。要保留 lazy-key 插件的绑定，必须在 nvchad.mappings 之后重新显式绑定，不能指望 lazy.nvim 的 keys stub 幸存。

## 验证手法

nvim --headless -c 'lua print(vim.inspect(vim.fn.maparg("<C-h>","n",false,true)))'（需要时用 TMUX=fake nvim ... 模拟环境变量门禁），看 desc/rhs 到底是谁的映射赢了。
