---
id: nvim-env-var-not-auto-vim-g-use-os-getenv
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, lua, env, vim.g, os.getenv, testing]
triggers:
  - "给 nvim 传环境变量后 Lua 里读 vim.g 拿不到（失败信号）"
  - "写 nvim 自动化测试脚本，想用环境变量控制分支"
  - "env VAR=x nvim ... 跑了几轮都像『什么都没做』"
  - "在 nvim Lua 里读外部环境变量/配置开关"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: human
source: session:01a0a3bd-e792-7545-a9df-8e091dcd100f
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [nvim-stub-external-command-count-invocations]
---

# 环境变量不会自动注入 vim.g，nvim Lua 里要用 os.getenv()/vim.env 读

## 主张

从 shell 用 `env VAR=x nvim ...`（或 `VAR=x nvim ...`）传进 nvim 的环境变量，不会自动变成 `vim.g.VAR`。Lua 脚本若用 `vim.g.VAR` 去读它，只会拿到 nil，导致脚本静默走「默认/什么都不做」分支——不报错，极难察觉。

## 为什么

`vim.g.*` 是 nvim 自己的全局变量表，和环境变量（`$VAR`）是两个独立命名空间，不存在自动镜像。读进程环境变量要走 `os.getenv('VAR')`（或 nvim 内置的 `vim.env.VAR`），才能拿到 shell 里传进来的值。

## 反例 / 边界

- 正确读法：`os.getenv('REPRO_EXIT_MS')` 或 `vim.env.REPRO_EXIT_MS`；要写回则 `vim.env.FOO = 'bar'`（会自动同步到子进程环境）。
- 失败信号识别：给 nvim 传了环境变量、脚本跑了几轮行为却和「没传」完全一样（比如一个靠环境变量控制退出的测试三轮都走默认分支），先怀疑是不是读错了变量表。
- 与 shell 区分：在纯 shell 脚本里 `$VAR` 读环境变量没问题，坑只出在「Lua 脚本以为 vim.g 会自动继承环境」这个错觉上。

## 证据

切片命令↔结果（session 2026-09-15 调试 nvim PDF 外部打开，测试脚本用环境变量控制退出时机）：

- 测试外壳 `run()` 用 `env "$@" nvim ...` 传入 `REPRO_EXIT_MS=700`，期望脚本按该值延时后自动退出。
- 多轮输出显示脚本一直只走「delete-only」路径、退出分支从未触发（`### X 单参数 · delete only` / `FIRE ... SCHED-ENTER ...`，无延时退出事件）。
- 末条 assistant 自诊断：`环境变量传错了（vim.g 没设上，三轮都跑的是 "什么都不做"）。重跑：`——即环境变量未进 vim.g，脚本读空。

> 注：根因归属（环境变量 vs vim.g 命名空间错位）是本次会话的人工诊断，切片止于「重跑」，未捕获修复后复跑的对照结果，故 verified_by 标 human。
