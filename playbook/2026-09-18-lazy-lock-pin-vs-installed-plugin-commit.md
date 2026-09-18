---
id: lazy-lock-pin-vs-installed-plugin-commit
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, lazy.nvim, lazy-lock, plugin-source, version]
triggers:
  - "要在结论/报告里引用某个 nvim 插件的源码行或行为"
  - "排查插件问题前想确认 lazy 目录里检出的源码就是实际加载的那份"
  - "lazy-lock.json 记的 commit 与 ~/.local/share/nvim/lazy/<plugin> 的 HEAD 对不上（失败信号：结论可能基于另一个版本的代码）"
  - "本地改过插件源码 / 手动切过分支后，nvim 行为与官方该版本代码不符"
  - "要回答『这个插件装的是哪个 commit / 哪个版本』"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e625-725c-a75a-f9838675a59a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
---

# 引用 nvim 插件源码下结论前，用插件目录的 git log -1 与 lazy-lock.json 的 pin 对齐

## 主张

lazy.nvim 把每个插件以**独立 git 仓库**形式装在 `~/.local/share/nvim/lazy/<plugin>/`，
`lazy-lock.json` 里每个插件的 `commit` 字段就是锁定版本。因此"我读的插件源码 / 我引用的那个行为"
可以也必须被钉到一个具体 commit：在插件目录跑 `git log -1`，与 lock 里的 commit 对齐——
一致才能说"这就是当前 nvim 加载的代码"；引用源码行级结论时把该 commit 写进结论里。

## 证据（本会话命令 ↔ 结果）

- 读锁文件：
  `$ rg -n -i 'flatten' /Users/zodyne/Dev/dotfiles/config/nvim/ …; echo "--- lock ---"; rg -n -A2 'flatten' /Users/zodyne/Dev/dotfiles/config/nvim/lazy-lock.json`
  → `/Users/zodyne/Dev/dotfiles/config/nvim/lazy-lock.json:12:  "flatten.nvim": { "branch": "main", "commit": "d92ca41e9c330f…`
- 读插件目录实际 HEAD：
  `$ cd /Users/zodyne/.local/share/nvim/lazy/flatten.nvim && git log -1 --format='%h %ad %s' --date=iso 2>&1`
  → `d92ca41 2026-06-19 14:40:11 +0000 chore(docs): autogenerate vimdoc`
  —— 与 lock 里 pin 的 `d92ca41e9c330f…` 是同一个 commit（hash 前缀一致），
  所以本会话里对 `lua/flatten/*.lua` 行号的引用确实指向"锁定版本 + 实际检出"的那份代码。
- 同一目录确实按插件名平铺：`ls ~/.local/share/nvim/lazy/` → `base46 … conform.nvim flash.nvim flatten.nvim friendly-sn…`，
  每个目录可 `cd` 进去当 git 仓库用（上一条命令 `cd …/flatten.nvim && git log` 即在证明这点）。

## 边界 / 反例

- 本条主张的是"**用 lock + `git log -1` 把结论钉到 commit**"这个动作，不是"两者永远一致"。
  一旦对不上，说明本地 lazy 目录被改动过 / 没按 lock 同步，此时任何"源码第 N 行如何"的结论都必须标注实际 HEAD，
  否则等于拿 A 版本代码去解释 B 版本行为。
- 本会话只核对了 `flatten.nvim` 一个插件，没有逐个插件比对；不要把"这次一致"推广成"全仓库都一致"。
- lock 里的 commit 只说明"锁定的是哪个版本"，**不说明 nvim 运行时真的加载了它**——两者是互补证据，
  本条只负责把"读到的源码"这一步钉死。
