---
id: lua-gsub-multireturn-pitfall-in-fn-args
type: lesson
status: candidate
scope: global
domain: lua
tags: [lua, string, gsub, multiple-return-values, debugging, neovim]
triggers:
  - "Lua 里把 str:gsub(...) 直接当另一个函数调用的最后一个参数传"
  - "fn(x:gsub(p, repl)) 报 'attempt to index a number value'"
  - "string.gsub / string.match 的结果作为参数传递时行为异常"
  - "Lua 函数意外收到多余参数 / 多返回值泄漏进实参"
created: 2026-07-27
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:019fa11b-e83c-78ff-a701-e0f1d363d3af
last_verified: 2026-07-27
superseded_by: null
schema_version: 1
---
`string:gsub` 返回**两个值**（结果字符串、替换次数）。当 `x:gsub(...)` 是函数调用的**最后一个实参**时，Lua 会把两个返回值**都**追加进参数列表。于是 `fn(x:gsub(p, repl))` 等价于 `fn(result_string, count)`——第二个参数被多出来的 `count`（number）占掉。

**本会话实例**：`local norm = vim.fs.normalize(search:gsub("^@", ""))`。`vim.fs.normalize(path, opts)` 的 `opts` 期望是 table，却收到 gsub 的次数（number），normalize 内部一索引就炸：`vim/fs.lua:0: attempt to index a number value`。finder 因此返回 0 项。

**修复**：把 gsub 拆成独立语句，只取第一个返回值——
```lua
local query = search:gsub("^@", "")
local norm = vim.fs.normalize(query)
```
或显式截断多返回值：`vim.fs.normalize((search:gsub("^@", "")))`（外层括号只保留首个返回值）。改完实测 `[~/.claude/backups/] OK -> 7 items`。

**证据**：会话里 `/tmp/test_err.lua` 复现 `!!! PCALL ERROR: vim/fs.lua:0: attempt to index a number value`；随后 `sed` 把单行 gsub 改写成两行，输出 `=== 修复 gsub 多返回值后 === OK -> 7 items`。前面 `/tmp/test_dbg{,2,3}.lua`、`/tmp/test_full.lua` 连续多轮排查都因为被 pcall 吞掉真实报错而走偏——直接去掉 pcall 暴露 traceback 才定位到 normalize。

**边界**：同样适用于 `string.match`（多捕获组）、`pcall`（ok+ret...）、任何多返回值函数。只要它处于实参列表末尾就会"漏"出多个值；不在末尾时 Lua 只取第一个返回值（不会泄漏）。排错信号：报错指向被调函数内部"index a number/string/nil value"、且实参里出现了不该有的 number——先怀疑末位实参是多返回值函数。
