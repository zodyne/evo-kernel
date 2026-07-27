---
id: nvim-headless-blocked-by-flatten-nvim
type: lesson
status: candidate
scope: global
domain: nvim
tags: [neovim, headless, flatten-nvim, nvim-env, automation, config-testing]
triggers:
  - "nvim --headless 跑 lua 报 flatten/rpc.lua 的 stack traceback"
  - "脚本/CI 里 nvim --headless 被 flatten.nvim 拦截异常退出"
  - "在 nvim 内置终端（$NVIM 已设）里再起 nvim --headless 失败"
  - "批量验证 nvim 配置时 headless 调用报 rpc 错误"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fa11b-e83c-78ff-a701-e0f1d363d3af
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
装了 **flatten.nvim** 的环境下，直接 `nvim --headless +'lua ...'` 会被 flatten 拦截：flatten 检测到外层 nvim（通过继承的 `$NVIM` 环境变量——在 nvim 内置终端或嵌套调用里它已被设值），试图把子进程 rpc 回父实例，导致 `flatten/rpc.lua` 报错、headless 命令拿不到预期输出。

**本会话实例**：`nvim --headless +'lua local M=require("configs.picker") ...'` 直接报 `✗ stack traceback: .../flatten.nvim/lua/flatten/rpc.lua:36: in function 'e...'`；`echo "NVIM env"` 显示 `NVIM env = [/var/folders/.../nvim.zodyne/swz9JY/nvim.85589.0]`（从父 nvim 继承）。

**修复（两件套一起上）**：
```bash
env -u NVIM nvim --headless --cmd "let g:flatten_disable=1" +'lua ...' +'lua print(...)' +qa
```
- `env -u NVIM` 清掉继承来的 `$NVIM`，flatten 就找不到"父 nvim"；
- `--cmd "let g:flatten_disable=1"` 在加载插件前显式禁用 flatten。
实测改写后输出 `open_path=function files=function files_all=...`（正常返回）。

**证据**：切片中失败命令 traceback 指向 `flatten/rpc.lua:36`；改写为 `env -u NVIM nvim --headless --cmd "let g:flatten_disable=1"` 后同一段 lua 正常打印函数类型。注意会话里也曾单独 `env -u NVIM`（未加 flatten_disable）仍带 ✗——所以两者并用最稳。

**边界**：只在装了 flatten.nvim 且存在外层 nvim（`$NVIM` 已设）时触发；普通终端裸跑 `nvim --headless` 不会中招。若不能用 `env -u`（某些受限 shell），改 `unset NVIM` 或 `NVIM= nvim ...` 同效。排错信号：headless 脚本时报 traceback 里出现 `flatten` 字样，且 `echo $NVIM` 非空——直接套两件套。
