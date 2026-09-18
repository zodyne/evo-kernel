---
id: zshrc-alias-missing-in-noninteractive-bash
type: lesson
status: validated
scope: global
domain: shell
tags: [zsh, bash, alias, noninteractive, macos, command-not-found]
triggers:
  - "agent/脚本起的 bash -c 里 python 报 command not found，但用户在终端里能用"
  - "在 ~/.zshrc 写了 alias 或函数，脚本/非交互 shell 里却找不到同名命令"
  - "排查为什么 harness 起的非交互 shell 没有某个用户已配置的命令"
  - "给 agent 写要在非交互 shell 跑的命令，误以为会吃到用户的 shell 别名"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a2fa-50a4-75b4-998b-45eb62b3fbfb
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [load-api-key-from-zshrc-subshell]
---

用户在 `~/.zshrc` 里定义的 shell 别名（如 `alias python='python3'`）只对交互式 zsh 生效；agent/脚本用 `/bin/bash -c` 起的非交互 shell 不加载 `.zshrc`，于是 `python` 报 `command not found`，尽管用户终端里能用。

为什么：非交互 bash（以及 `sh -c`）不会 source 交互式 rc 文件，别名是交互式 shell 语法，根本传不进子进程。agent 若按交互终端经验判断，会误判环境坏了、去装 python，实际只需用真实二进制名。

反例/边界：与 `load-api-key-from-zshrc-subshell` 讲的 env var 是两回事——export 的环境变量可以在子 shell 里 source `.zshrc` 补回来；别名无法 source 进 bash，只能换真实命令名（写 `python3`，不写 `python`）。`~/.bashrc` 里的 alias 同理只对交互 bash 生效。

证据：`python` 执行 → `/bin/bash: python: command not found`；`rg -n 'alias python|python=' ~/.zshrc` → `~/.zshrc:130:alias python='python3'`；改用 `python3` 后命令正常执行。
