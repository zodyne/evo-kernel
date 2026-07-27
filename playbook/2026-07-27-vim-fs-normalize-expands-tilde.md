---
id: vim-fs-normalize-expands-tilde
type: lesson
status: validated
scope: global
domain: nvim
tags: [neovim, vim-fs, path-handling, tilde-expansion, lua]
triggers:
  - "Lua/nvim 里要手动把 ~ 展开成 home 目录绝对路径"
  - "处理用户输入的含 ~ 的路径（@~/... 或 ~/foo）"
  - "不确定 vim.fs.normalize 是否展开 tilde/是否还需 os.getenv('HOME')"
  - "snacks/util 拼 item.cwd + item.file 前需要路径归一化"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fa11b-e83c-78ff-a701-e0f1d363d3af
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
Neovim 的 `vim.fs.normalize(path)` 会**展开 `~`** 为家目录绝对路径，无需自己 `os.getenv("HOME")` 手拼。snacks.nvim 的 `util.path(item)` 内部正是 `vim.fs.normalize(item.cwd and item.cwd .. "/" .. item.file or item.file)`——所以把含 `~` 的路径喂进 item.cwd/file，最终 `vim.cmd("edit " .. path)` 能直接打开。

**本会话实例**：finder 接收用户输入 `~/.claude/backups/`，直接 `vim.fs.normalize(query)` 归一化成 `/Users/zodyne/.claude/backups` 再 `uv.fs_stat`，无需额外展开。

**证据**：切片里 `/tmp/test_expand.lua` 实测输出：
```
vim.fs.normalize('~')            = "/Users/zodyne"
vim.fs.normalize('~/.claude/backups') = "/Users/zodyne/.claude/backups"
```
另一条 `=== vim.fs.normalize 对 ~ / $VAR / 通配符的行为 ===` 也给出 `~/.claude/backups -> /Users/zodyne/.claude/backups`。

**边界**：normalize 做的是路径**字符串归一化**（展开 `~`/环境变量、折叠 `..`/`.`、小写化 Windows 盘符），**不做 glob 通配符展开**——`*`/`?` 不会被解析成文件列表，要列目录请用 `vim.fs.dir`/`uv.fs_scandir`。`~` 只在路径**开头**时被当作家目录；出现在中间（`a/~b`）不展开。排错信号：发现自己正在写 `path:gsub("^~", os.getenv("HOME"))` 之类手展——先试 `vim.fs.normalize`。
