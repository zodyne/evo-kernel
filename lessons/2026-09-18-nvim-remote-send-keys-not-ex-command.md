---
id: nvim-remote-send-keys-not-ex-command
type: lesson
status: candidate
scope: global
domain: nvim
tags: [nvim, remote-send, remote-expr, server-socket, terminal-buffer, silent-failure]
triggers:
  - "要让宿主 nvim 执行一段 lua 脚本并取回结果，准备用 nvim --server $NVIM --remote-send"
  - "remote-send 之后毫无报错，但脚本该写的报告文件不存在（失败信号）"
  - "宿主当前窗口/buffer 是内嵌终端（term://... 里跑 pi/claude）"
  - "需要直连活着的 nvim 实例跑脚本又不想赌它当前处在什么模式"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b351-8a08-7097-91f3-80fbeb2387b2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [debug-nvim-lsp-via-live-server-socket]
---

# `--remote-send` 投的是按键不是命令：宿主停在终端 buffer 时脚本静默不执行，取结果要用 `--remote-expr`

## 主张

`nvim --server "$NVIM" --remote-send ':luafile x.lua<CR>'` 是「把按键投进宿主」，它不回传任何东西；宿主当前窗口若是内嵌终端（`term://...` 里跑着 pi/claude），这些按键会按当前 mode 落到子进程里，脚本根本没执行——**没有任何报错**，只能从「该生成的报告文件不存在」反推。同一脚本改用 `nvim --server "$NVIM" --remote-expr 'execute("luafile x.lua")'` 立刻执行并回传输出。

## 为什么

`--remote-send` 走输入路径（等同手敲键），成败取决于宿主此刻的 mode / 当前 buffer；`--remote-expr` 走 RPC 求值路径，同步执行并返回结果，与 UI 状态无关。要「驱动宿主并取回结果」时只有 remote-expr 是可靠通道。

## 证据（切片命令↔结果）

同一脚本 `/tmp/nvim-probe/inspect.lua`（把宿主状态写进 `/tmp/nvim-probe/host-state.txt`），连续两次、两种通道：

- `$ nvim --server "$NVIM" --remote-send ':luafile /tmp/nvim-probe/inspect.lua<CR>'; sleep 1; cat /tmp/nvim-probe/host-state.txt`
  ↳ `✗ cat: /tmp/nvim-probe/host-state.txt: No such file or directory`（脚本没跑，且无任何报错）
- `$ nvim --server "$NVIM" --remote-expr 'execute("luafile /tmp/nvim-probe/inspect.lua")' 2>&1 | tail -3; sleep 1; cat /tmp/nvim-probe/host-state.txt`
  ↳ `cur_buf=term://~/Dev/algommw-plus//82462:/opt/homebrew/bin/pi cur_alt=term://~/Dev/algommw-plus//73476:/opt/homebrew/bin...`（执行成功、报告有内容）

宿主当时的当前窗口正是内嵌终端：`getwininfo()` 回显 `=== current === term://~/D...`。

## 反例 / 边界

- 同一会话更早一次 `--remote-send ':luafile /tmp/nvim-probe/cleanup.lua<CR>'` 是**成功**的（`removed count=2 ... remaining buffers=9 wins=3`）。所以不是「remote-send 必失效」，而是条件性的：依赖宿主当时的 mode/焦点落在哪个 buffer。既然赌不起，「要结果就换 remote-expr」。
- 本次未逐步验证按键到底落到了哪里（推测是被投进终端里的子进程），但「remote-send 无回传、失败不报错」与「remote-expr 同步回传」这两点已被上面的对照证据坐实。
- 多行 lua 写成文件再 `--remote-expr 'execute("luafile ...")'`，比把引号塞进 `--remote-expr` 稳。
