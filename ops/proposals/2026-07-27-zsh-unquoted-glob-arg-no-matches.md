---
id: 2026-07-27-zsh-unquoted-glob-arg-no-matches
type: playbook
status: candidate
scope: global
domain: shell
tags: [zsh, bash, shell, glob, grep, find, macos, quoting]
triggers:
- 在 zsh（macOS 默认 shell）里跑 grep --include=*.py / find -name *.py 报 "no matches found"
- 从 bash 习惯照搬的命令在 macOS 上静默退出非零且无输出
- 命令参数里带 *.py / *.md 这类通配符，zsh 报 "no matches found: <那个参数>"
- 想确认是 shell 把通配符先吃了，还是命令本身的问题
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:9c7257e9-4890-48f8-b144-4f90a46031e3
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---

# zsh 会先展开命令参数里的裸通配符：grep --include=*.py 报 "no matches found"

zsh（macOS Catalina 起的默认 shell）会**先于命令**对参数里的通配符做 glob 展开。当 `--include=*.py`、`-name *.py` 这类参数里的 `*.py` 在当前目录没有匹配项时，zsh 直接报 `no matches found: --include=*.py`（或 `no matches found: *.py`）并让命令以非零退出、无任何输出。这跟 bash 不同——bash 在无匹配时会把裸 token 原样传给命令，命令再自行当 glob 用。**修法：给通配符加引号**（`--include='*.py'`、`-name '*.py'`），让它原样到达命令。

## 为什么

`--include=*.py` 看起来是"给 grep 的选项"，但在 zsh 眼里 `*.py` 是一个待展开的 glob；当前目录若没有 `.py` 文件，zsh 的默认行为（`NOMATCH` 未关）是报错中止，命令根本没机会运行。报错信息把整个参数原样打出来（`no matches found: --include=*.py`），很容易被误读成"grep 不认这个选项"。本会话第一版循环 `grep -rln "$m" --include=*.py ...` 全部 `Exit code 1 / no matches found: --include=*.py`；把通配符加引号改成 `--include='*.py'` 后立即正常列出文件。同坑见于 `find -name`、`rg -g`、`tar` 等"参数里带 glob"的命令。

## 怎么修 / 怎么辨

- **加引号**：`--include='*.py'`、`-name '*.py'`、`-g '*.md'`——单引号最稳，不被变量展开干扰。
- **辨误**：看到 `no matches found: <某个你写的参数>` 且退出码非零、无命令自身输出，先怀疑是 zsh 替你展开了通配符，而非命令报错。
- 临时绕过：`setopt NO_NOMATCH`（或 `unsetopt nomatch`）让无匹配时原样传参，但改全局选项不如加引号便携。

## 边界

- bash 下不加引号通常也能跑（无匹配时原样传递），所以"在 bash 好好的命令到 mac 就坏"是典型信号。
- 若当前目录**恰好**有匹配文件，zsh 会把 `*.py` 展开成那些文件名、拼进参数（如 `--include=a.py`），命令行为扭曲但不报错——更隐蔽，加引号同样根治。
