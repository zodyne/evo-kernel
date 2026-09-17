---
id: nvim-feedkeys-x-flag-skips-remap
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, feedkeys, keymap, headless, remap, testing]
triggers:
  - "用 nvim_feedkeys 复现/测试键位映射时映射不触发"
  - "headless 脚本里想模拟按键触发 <leader> 映射"
  - "feedkeys 后映射触发次数为 0（失败信号）"
  - "不确定 feedkeys 的 mode 标志该用 x 还是 m"
created: 2026-09-14
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a09f1a-ce5f-74d6-aeb7-1ea49cc22f12
last_verified: 2026-09-14
superseded_by: null
schema_version: 1
related: [nvim-insert-mode-leader-single-char-eats-typing]
---

# nvim_feedkeys 不带 "m" 标志按字面执行、不触发重映射（<leader> 映射不生效）

## 主张

用 `vim.api.nvim_feedkeys(...)` 模拟按键去验证/触发某个映射时，若 mode 标志不含 "m"（remap），feedkeys 会按字面把字符灌进去、不触发重映射——`<leader>` 之类的映射根本不生效（触发次数 0）。要触发重映射，mode 要带 "m"（如 "mx"）。

## 为什么

feedkeys 的 mode 标志里 "x" 表示「按输入原样执行、不重映射」，"m" 才是「允许重映射」。默认/字面模式下 `<Space>w` 只会被当普通字符处理，不会命中已注册的映射。

## 反例 / 边界

- 验证映射是否触发时，用 `"mx"`（m=允许重映射）；验证「映射不存在时输入是啥样」这类对照场景，才用不带 m 的字面模式。
- 这是写 headless 复现脚本时最常见的坑：脚本跑了但映射「没反应」，先查 feedkeys 的 mode 标志，而不是先怀疑映射本身。

## 证据

切片里 headless 复现 insert 模式 `<Space>w` 映射时的两版对比：
- 字面模式：`缓冲区内容 = [hello world]  <leader>w 触发次数 = 0`。
- 改用 "mx"：`缓冲区 = [helloorld]  <leader>w 触发 = 1`（映射被触发、吞掉空格+w）。
