---
id: nvim-headless-hangs-without-explicit-quit
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, headless, hang, timeout, qa, testing]
triggers:
  - "用 nvim --headless 跑脚本/体检/测试却一直不返回"
  - "headless nvim 命令卡住直到超时（失败信号）"
  - "写 nvim --headless 的自动化测试或诊断脚本"
  - "nvim -u NONE --cmd 'luafile ...' 无输出地挂死"
  - "headless 调试 nvim 的 autocmd/BufReadCmd 行为"
created: 2026-09-17
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a3bd-e792-7545-a9df-8e091dcd100f
last_verified: 2026-09-17
superseded_by: null
schema_version: 1
related: [flatten-nvim-nest-headless-crashes-host]
---

# nvim --headless 不显式退出就会挂死到超时，必须带 `-c 'qa!'` 或脚本内 `qa!`

## 主张

用 `nvim --headless` 跑一次性脚本（体检、探针、autocmd 复现）时，如果脚本本身不主动退出（`vim.cmd('qa!')` / `-c 'qa!'`），nvim 会一直挂着不返回，命令只能在超时后被外部杀掉——即使脚本已经执行完了所有逻辑也一样。

## 为什么

`--headless` 只是关掉了 UI，nvim 的事件循环、buffer、autocmd 全部照常运行。脚本跑完后没有退出信号，nvim 就停留在「等待输入」的空转态。`-u NONE` 也救不了——它只清空配置，不改变「不退出就一直活着」这个事实。

## 反例 / 边界

- 兜底写法：`nvim --headless -u <rc> -c 'qa!' <file>`，把 `-c 'qa!'` 作为最后一条命令，逻辑无论走到哪都会收尾退出。
- 脚本内部兜底：在 `luafile` 的脚本末尾加 `vim.cmd('qa!')` 或 `vim.defer_fn(function() vim.cmd('qa!') end, N)`，比依赖命令行 `-c` 更稳（尤其当脚本里有 `vim.schedule` 异步逻辑时）。
- 失败信号识别：headless nvim 命令「一直没返回 / 被外部超时杀」几乎总是指向缺少显式退出，先查这个，别先去怀疑脚本逻辑死循环。

## 证据

切片命令↔结果（session 2026-09-15 调试 nvim PDF 外部打开）：

- 无退出收尾：`nvim --headless -u /tmp/pdf_test/argcheck.lua /tmp/pdf_test/probe.pdf 2>&1 | head -2` → `✗ Command timed out after 120 seconds`。
- 加 `-c 'qa!'` 后同一探针立即返回：`nvim --headless -u /tmp/pdf_test/argcheck.lua -c 'qa!' /tmp/pdf_test/probe.pdf ...` → `VIMRC argc=1 argv=[...] bufs=1 ...`（正常输出，不再超时）。
- 后续测试统一采用「加超时兜底 qa」的做法（`T3 原始输出（无 grep，加超时兜底 qa）`）后全部正常返回。
