---
id: debug-nvim-lsp-via-live-server-socket
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, LSP, clangd, remote-expr, socket, 跳转失效]
triggers:
  - nvim LSP 跳转失效、snacks picker 报 No results found for lsp_definitions
  - 想直连活着的 nvim 实例读 window/buffer/光标
  - 用 lsof 找 nvim socket、nvim --server --remote-expr 跑 lua
  - 空结果就被当成跳转坏了（失败信号：没验证光标真实位置）
  - 需要复现 textDocument/definition 请求
created: 2026-09-07
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: capture:capture-2026-09-07-07-00-22-970-vqi7
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [clangd-subproject-missing-compile-commands-failed-to-find]
---

# 排查 nvim LSP 跳转失效：别猜，直连活着的 nvim 实例

排查 nvim LSP 跳转失效:别猜,直连活着的 nvim 实例。

## 方法

socket 用 lsof -p <nvim pid> | grep nvim.<pid>.0 找;然后 nvim --server $SOCK --remote-expr "luaeval(\"dofile('/tmp/q.lua')\")"(把 lua 写进文件再 dofile,避免 --remote-expr 的引号地狱)即可读 window/buffer/光标,并直接跑 vim.lsp.buf_request_sync 复现 textDocument/definition。

## 结论 / 边界

本次结论:LSP 完全正常,光标停在注释里的 @date 上,clangd 正确返回空,snacks picker 报 'No results found for lsp_definitions'——空结果 != 跳转坏了,先验证光标真实位置。

macOS 上 socket 不在 `/tmp`: `ls /tmp/nvim.*`、`find /tmp -name '*.sock'` 返回空**不代表**没有可连实例——
实际路径是 `$TMPDIR/nvim.<用户名>/<6 位随机串>/nvim.<pid>.0`(`$TMPDIR` = `/var/folders/<xx>/…/T/`)。
先用 `ls -d "$TMPDIR"nvim."$USER"/*/nvim.*.0` 列候选、`[ -S "$f" ]` 判真 socket 再连;同一个用户会积累多个随机子目录
(含已死进程的残留 socket),列表非空 != 有可用实例,连之前先 `ps` 对 pid。上面那条 `lsof` 只在已知 pid 时更稳。
