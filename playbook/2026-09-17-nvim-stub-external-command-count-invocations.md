---
id: nvim-stub-external-command-count-invocations
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, headless, stub, debug, external-command, autocmd]
triggers:
  - "验证 nvim 里外部命令（open/系统默认程序）到底被调了几次"
  - "排查 nvim 打开文件时外部程序被重复调用/多次触发（失败信号）"
  - "headless 调试 nvim 的副作用命令，想看调用次数与参数"
  - "不确定某 autocmd/插件有没有真的调用外部命令"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a3bd-e792-7545-a9df-8e091dcd100f
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [nvim-env-var-not-auto-vim-g-use-os-getenv]
---

# 调试 nvim 外部命令副作用：把命令替换成 stub 记日志，数调用次数而非靠肉眼

## 主张

要验证「nvim 打开某类文件时，系统外部命令（如 macOS 的 `open`）被调用了多少次、带什么参数」，最可靠的做法不是读代码或猜，而是把那个外部命令替换成一个 stub（记录每次调用的参数 + 时间戳并打日志），再 headless 跑一遍数调用次数。调用次数、参数、触发时机三个事实一次拿到。

## 为什么

「外部命令被调几次」是副作用行为，源码里读 autocmd 只能看到「可能触发」，看不到运行时实际触发了几次（一个 autocmd 可能被多个事件重复触发）。把命令替换成 stub 后，每次真实调用都会留痕，调用次数变成可直接数的事实，而不是推理。

## 反例 / 边界

- stub 安装时机：必须在 nvim 启动早期（`--cmd` 或 init 里）就把外部命令换成 stub，再 `luafile` 加载探针脚本，否则早期触发漏记。
- 与「期望」对账：stub 日志要能和测试标题里的「期望调用 N 次」逐条对照（如 `T1 期望 open 只调 1 次` vs 实际 stub 记录了几次），差异就是 bug 线索。
- 失败信号识别：headless 复现「副作用命令重复触发」，用 stub 把「调了几次」变成数字，比反复加 debug print 高效。

## 证据

切片命令↔结果（session 2026-09-15 调试 nvim 打开 PDF 时 `open` 外部命令的触发次数）：

- 采用 stub 包装 `open`（`JOBSTART-STUB`）后，多组 headless 测试直接打出调用事实：`T1: JOBSTART-STUB: { { "open", "/private/tmp/pdf_test/probe.pdf" }, ... }`；`T5 同会话两次 :edit —— 期望 2 次 open` 也以 stub 日志对账调用次数。
- 通过 stub 日志区分出 `open` 参数、`detach` 标志、以及单/双参数启动下的调用差异，直接支撑「只调一次 + 自动退出」的验收目标。
