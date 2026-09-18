---
id: lazy-plugin-checkout-not-running-instance-code
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, lazy-nvim, hot-reload, plugin-version, remote-expr, runtime-code]
triggers:
  - "在 ~/.local/share/nvim/lazy/<plugin> 里 git checkout / Lazy! update 换版本后，拿正在运行的 nvim 验证新版本行为"
  - "用 --remote-expr 探针看到活实例内存里还是旧版插件的特征（失败信号：磁盘已是新版）"
  - "热加载插件后用同一路径/同一行对比，结果与全新启动不一致"
  - "想不重启 nvim 验证插件升级/配置改动"
  - "写 nvim 插件问题的结论时，要确认复现它的那份代码到底是磁盘的哪一版、实例跑的哪一版"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b29d-0cb6-7097-91f3-80f8d5ba1119
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [lazy-lock-pin-vs-installed-plugin-commit, nvim-config-live-dir-is-dotfiles-symlink, render-markdown-wide-table-needs-v814-multiline-cells]
---

**主张**：`~/.local/share/nvim/lazy/<plugin>` 只是**磁盘上的源码**；已经在运行的 nvim 实例内存里跑的是**启动时加载的那份代码**。在插件目录 `git checkout <tag>` / `Lazy! update` 之后，活实例仍然是旧版——拿它去"验证新版本行为"会得到旧版结果，而磁盘状态看上去完全正常，没有任何报错。要对比版本行为：新起实例，或者显式热加载（重新 `require` + `setup`），并且**用"同一访问路径 vs 全新启动"逐格对照**来自证热加载真的生效。

**证据**（会话 01a0b29d 切片，命令 ↔ 结果）：
- 磁盘已升级、实例内仍是旧版：`Lazy! update render-markdown.nvim` 完成后，探针读活实例（PID 82380，2026-09-17 启动）→ `--- 内存中的插件版本特征（v8.14 才有 pipe_table.default.wrap）--- v8.13 (no wrap) --- 热加载 --- render-markdown reloaded v8.14.0 -> v8…`；即同一时刻磁盘是 v8.14、内存特征还是 v8.13。
- 测试脚本自己也把这两个版本分开标注：`磁盘插件版本（启动前）: v8.13.0-1-g4663eb3 --- [1] 热加载前（实例内跑的是 v8.13）--- …`。
- 热加载后必须对照：第一版热加载脚本报出差异（`notify -> nvim_echo line 58: 有差异 ⚠️ 1,4d0 <   │ §8.4…`），修好后再测 → `同一访问路径 (40 -> 58): 热加载后与全新启动**逐格一致** ✅`。
- 对照实验本身用的是新实例：`run_real.sh "AFTER v8.14.0" …` 每次起 fresh nvim 截屏，所以 BEFORE/AFTER 的差异可信。

**边界/反例**：
- 这条与 `lazy-lock-pin-vs-installed-plugin-commit` 互补但不同：那条解决"我读的源码是哪一版"（lock + `git log -1`），本条解决"实例**跑**的是哪一版"；两者都对齐了才能说"这个行为属于这个版本"。
- 热加载不是等价于重启：本会话第一次热加载就出现了与全新启动不同的渲染（第 58 行 1,4d0 差异），修掉后才一致——所以**热加载后未对照就可能拿到假结果**，别把"热加载没报错"当成"新代码已生效"。
- 本条只覆盖 lazy.nvim 目录式插件；非 lazy 管理（直接写进 runtimepath）的插件另说。
