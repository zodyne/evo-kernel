---
id: config-symlink-reference-scan-before-delete
type: lesson
status: validated
scope: global
domain: macos
tags: [symlink, readlink, dotfiles, deletion-safety, config]
triggers:
  - "删除/搬迁一个可能被软链引用的目录（dotfiles、配置仓库）"
  - "怀疑 ~/.config/* 是软链，但不知道各自指向哪里"
  - "搬迁后 nvim/kitty/tmux 读到旧配置或报错（失败信号）"
  - "判断某个目录能否安全删除"
  - "同名仓库搬迁前要确认有没有配置仍指向旧位置"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a8c1-5e3e-710a-b61a-fd2478c30f87
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [same-name-repo-verify-by-remote-url]
---

**主张**：删除/搬迁一个「看起来是自己的副本」的目录（dotfiles、配置仓库）之前，必须枚举隐藏引用：`~/.config/*` 下**有的项是软链、有的是真目录，不能一律假设**——本机 `~/.config/nvim` 是软链指向 `~/Dev/dotfiles/config/nvim`，而 `~/.config/kitty` 是真实目录；用 `readlink` / `ls -la | grep ' -> '` 逐项确认有没有软链指向待删目录，有引用就不能直接删。

**为什么**：软链是「文件系统外的依赖」，`ls` 待删目录时完全看不出来；删掉被引用的目录，症状是之后 nvim/tmux 等工具静默读到默认配置或直接报错，与删除动作间隔很远，极难归因。本会话把「软链指向 A（正牌 dotfiles）而不是待删的 B」作为删除 B 的前置证据之一。

**边界/反例**：软链扫描要覆盖家目录一级与 `~/.config/`（本机 `~/.tmux -> …` 也是软链），但不要用无路径的递归 grep 扫家目录（会触发 pi 的 bash-guard 拦截，见 `2026-09-16-bash-guard-blocks-pathless-recursive-scan`）；用 `ls -la`/`readlink` 这类非递归命令或指定文件清单。另外「无软链指向」只是必要条件，仓库身份仍要单独核对（见 related）。

**证据**（session 01a0a8c1，evo slice 「命令 ↔ 结果」）：
- `echo "==== ~/.config/nvim 指向 ===="; readlink ~/.config/nvim` → `/Users/zodyne/Dev/dotfiles/config/nvim`。
- `是否有软链/配置仍指向 B` → 输出分类为 `真实文件/目录（非软链）: /Users/zodyne/.config/kitty` 与 `软链他处: /Users/zodyne/.config/nvim -> /Users/zodyne/…`。
- `ls -la ~`（一级、不递归）→ `.tmux -> /Users/zodyne/.c…` 等软链条目。
