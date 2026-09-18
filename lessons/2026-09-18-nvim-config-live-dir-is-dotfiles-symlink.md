---
id: nvim-config-live-dir-is-dotfiles-symlink
type: fact
status: candidate
scope: global
domain: nvim
tags: [nvim, dotfiles, symlink, config-path, live-config]
triggers:
  - "要确认 nvim 实际读取的配置文件/目录到底是哪一个"
  - "改完 nvim 配置不确定改的是生效文件还是某份副本（失败信号）"
  - "ls -la ~/.config/nvim 的输出里带 ` -> `（软链指向 dotfiles 仓库）"
  - "nvim 配置修复只在 dotfiles 工作区（未提交），却要判断它是否已经生效"
  - "打算把 ~/.config/nvim 当独立副本备份/删除（失败信号：它是指向仓库的软链）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ab-4e97-725c-a75a-f987209df0c2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# 本机 `~/.config/nvim` 是指向 `~/Dev/dotfiles/config/nvim` 的软链：生效配置 = dotfiles 仓库文件

## 主张

`~/.config/nvim` 不是独立目录，而是软链 `-> /Users/zodyne/Dev/dotfiles/config/nvim`。因此「nvim 正在用的配置」与「dotfiles 仓库里的文件」是**同一份内容**：

- 改 `~/Dev/dotfiles/config/nvim/**` = 改 nvim 生效配置，不需要往 `~/.config/nvim` 再同步一份；
- 反向：dotfiles 工作区里**未提交**的改动也已经在 nvim 里生效（"生效" ≠ "入库"，参见 `uncommitted-fix-invisible-to-git-log-traceback` 形态的坑）；
- 要判断「修复是否已经作用到 nvim」时，对 `~/.config/nvim/<file>` 或 dotfiles 真身路径 rg 一次即可，两处必然同结果。

## 为什么

dotfiles 仓库的常见布局就是把 `~/.config/*` 指向仓库内的配置树，避免两处维护。这会让「路径」这个看起来最基础的前提失真：报告里写「改的是 ~/.config/nvim/...」，实际改的是仓库文件；把 `~/.config/nvim` 当独立副本去 cp/快照，会直接往仓库里塞文件。

## 证据（本会话切片命令 ↔ 结果）

- `$ ls -la /Users/zodyne/.config/nvim; ls -la /Users/zodyne/Dev/dotfiles/config/nvim` → `lrwxr-xr-x@ 1 zodyne staff 38 Mar 10 2026 /Users/zodyne/.config/nvim -> /Users/zodyne/Dev/dotfiles/config/nvim`。
- `$ echo "=== confirm live config path content has fix ==="; rg -n "no_files" /Users/zodyne/.config/nvim/lua/plugins/init.lua /Users/zodyne/Dev/dotfiles/config/nvim/lua/plugins/init.lua` → 命中 `/Users/zodyne/.config/nvim/lua/plugins/init.lua:44: no_f...`（软链两侧同一份内容，修复在"生效路径"上可见）。
- 本会话即靠这条确认：flatten.nvim 的 `no_files` 修复虽然只存在于 dotfiles 工作区（`git status` 为 ` M`），但 nvim 已经在跑它。

## 边界 / 反例

- 这是**本机实测的路径布局**：判定前先看一眼 `ls -la ~/.config/nvim` 有没有 ` -> `；一旦它被换成真目录（迁移/checkout 覆盖），本条结论失效。
- 软链两侧同一份内容只说明"路径等价"，**不**说明内容是对的、也不说明已入库——"修复是否已提交"要另查 git（见上文引用的坑）。
- 机器上其他 `~/.config/*` 项未必都是软链（本机就是有的软链、有的是真目录），不要把这台机器 `nvim` 这一例推广成"`~/.config/*` 全是软链"。
