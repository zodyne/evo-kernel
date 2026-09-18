---
id: render-markdown-wide-table-needs-v814-multiline-cells
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, render-markdown, pipe-table, wide-table, plugin-version, lazy-nvim]
triggers:
  - "nvim 里 md 宽表格（单元格或整行超过窗口宽）渲染错乱、被右边界截断、列错位"
  - "用 render-markdown.nvim 预览方案文档/PLAN.md，宽表格整块显示不正常，想改配置救"
  - "调研插件显示问题前，先核对本地 lazy 目录的 HEAD / lazy-lock 的 pin 是不是上游最新"
  - "本地插件版本落后于上游 release（失败信号：release notes 里已有对应 feature/fix）"
  - "render-markdown.nvim 宽表格折行 / multiline table cell rendering（上游 issue #616 cell-wrapping）相关"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b29d-0cb6-7097-91f3-80f8d5ba1119
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [render-markdown-long-line-wrap-self-excitation-flicker, lazy-lock-pin-vs-installed-plugin-commit]
---

**主张**：render-markdown.nvim 下 md **宽表格**显示混乱（长单元格被截断/列错位）时，先查插件版本再改配置——"宽表格折行"是 **v8.14.0（2026-09-14 发布）** 才引入的能力（`feat: multiline table cell rendering`，commit `a778444`，对应上游 issue #616 "Cell-wrapping for wide tables"）。本地 lazy 装的是 v8.13.x 时，无论怎么调 `pipe_table` 配置都拿不到折行；升级后才谈得上配置。

**为什么**：v8.13 及以前的 table renderer 把每行表格渲染成一条**整行虚行**（本会话探针结论"插件代码是 v8.14 的整行虚行"），宽度只由内容决定、不随窗口收紧，超出窗口就顶到右边界。折行是渲染器层面新增的能力，不是配置开关能补出来的。lazy.nvim 装的插件是独立 git 仓库、不会自动跟着上游 release 走——本例本地 HEAD 停在 `4663eb3`（2026-08-11 `fix: checkbox background…`，`git describe` = `v8.13.0-1-g4663eb3`），而 v8.14.0 已发布一个月。

**怎么修**：
1. `cd ~/.local/share/nvim/lazy/render-markdown.nvim && git describe --tags && git log -1 --format='%h %ad %s' --date=short` 看本地实际版本；
2. `nvim --headless "+Lazy! update render-markdown.nvim" +qa` 升级（本例 fetch 实测耗 75s，`Finished task fetch in 75036ms`）；需要钉版本就 `git checkout <tag-commit>`（本例 `640a3ec` → `git describe --tags` = `v8.14.0`）；
3. 升级后再在 render-markdown opts 里配 `pipe_table`（本会话在 `lua/plugins/init.lua` 加了 23 行，含 `preset = "round"`；探针显示 v8.13 没有、v8.14 才有的键是 `pipe_table.default.wrap`）。

**证据**（会话 01a0b29d 切片，命令 ↔ 结果）：
- 上游：`curl …/releases?per_page=8` → `v8.14.0 2026-09-15T06:00:08Z … - multiline table cell rendering ([a778444]…)`；`releases/tags/v8.14.0` → `# 8.14.0 (2026-09-14) ## Features - multiline table cell rendering`；`commits/a778444…` → `MSG: feat: multiline table cell rendering … the feature that I've had by far the most requests for, wide tabl…`；`issues/616` → `title = feature: Cell-wrapping for wide tables state = closed created_at = 2026-03-03`。
- 本地：升级前 `git describe --tags` → `v8.13.0-1-g4663eb3 4663eb3 2026-08-11`；`Lazy! update` 后同一目录 → v8.14.0。
- 效果：同一 pane、同一行（150x45 第 58 行）`run_real.sh "BEFORE v8.13.0"` 与 `"AFTER v8.14.0"` 两次真实 tmux 截屏内容不同；最终 120x36 的 FINAL 截屏里宽表格已按窗口折行。

**边界/反例**：本条只主张"宽表格折行要 ≥ v8.14.0"，不是"v8.14 能修好一切表格问题"——同插件另有长行导致 wrap/conceallevel 自激闪烁的独立问题（见 related）。另外本会话最终生效的渲染结果是"升级 + 配置编辑"两者叠加，没有单独做"只升级不改配置"的对照，所以不要把配置项的效果与版本效果混为一谈；要引用具体配置键名时以本地 `lua/render-markdown/settings.lua` 的类定义为准。
