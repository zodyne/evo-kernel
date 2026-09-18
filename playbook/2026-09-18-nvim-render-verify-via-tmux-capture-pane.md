---
id: nvim-render-verify-via-tmux-capture-pane
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, tmux, capture-pane, conceal, virt-lines, render-markdown, visual-verification]
triggers:
  - "要判断 nvim 显示类插件（conceal / virt_lines / 表格折行 / render-markdown）到底渲染成什么样"
  - "nvim --headless 只读到选项值（wrap=true、conceallevel=2），看不到屏幕结果（失败信号）"
  - "表格/长行在窗口里被截断或错位，需要量出实际渲染列宽"
  - "怀疑显示问题只在某个窗口宽度下复现"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b351-8a08-7097-91f3-80fbeb2387b2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [render-markdown-long-line-wrap-self-excitation-flicker, nvim-locate-option-toggle-via-setter-wrap-traceback]
---

# 验证 nvim 显示插件的真实渲染：起 tmux 真实 TTY + `capture-pane` 抓屏，再按东亚宽度算列宽

## 主张

headless 探针只能读到「选项/配置值」，拿不到 conceal / virt_lines / 表格边框这些**屏幕层**的渲染结果；要判定显示插件的实际效果，必须在指定尺寸的真实 TTY 里跑 nvim，用 `tmux capture-pane -p` 把屏幕抓成文本，再用 Python 按 `unicodedata.east_asian_width` 算每行显示宽度来量化（列宽、是否被截断、是否折行）。

## 证据（切片命令↔结果）

- 起真 TTY（固定尺寸，等价用户窗口）：`tmux -L nvimprobe new-session -d -s real -x 150 -y 45 '/bin/sh /tmp/nvim-probe/run-real.sh'`
  ↳ 抓屏 `=== screen (first 20 lines, widths) === 37 | | Component | Path /| 117 | Symbol ...`
- 逐行量宽度：python + `unicodedata.east_asian_width` → `total screen lines: 46   1 w= 37 ...   2 w=117 ...`
- 渲染结果直接可比：抓屏得到 `1 w=132 |╭───────────────────┬───...`（带边框表格，132 列）；同一张宽表（生成时列宽 24/120/100 → 254 列）在 150 列 pane 里实际占 132 列，由此可判「折行 vs 溢出」。
- 同期 headless 探针只给选项值：`nvim=0.12.4 ft=markdown columns=150 lines=45 EFFECTIVE win_wrap=true conceallevel=2 linebreak=true ...` —— 没有任何屏幕内容。

## 反例 / 边界

- TTY 里跑探针要先解决 `more` 分页卡死与显式退出（见 nvim-tty-probe-more-pager-blocks），否则抓到的只是半屏 message。
- `capture-pane` 抓的是「终端渲染后的文本」，宽度算的是显示单元格数而非字节/码点——含 CJK 或制表边框字符时必须按东亚宽度算。
- 抓屏的 `-x/-y` 要和真实窗口一致，否则复现不出「只在某宽度下出现」的显示问题。
- 该手段证明的是「屏幕上看起来如何」，不等于代码路径正确；归因仍要配源码/选项探针。
