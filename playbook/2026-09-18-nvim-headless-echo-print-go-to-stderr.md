---
id: nvim-headless-echo-print-go-to-stderr
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, headless, stderr, stdout, shell-capture, vimruntime]
triggers:
  - "用 `$(nvim --headless … +qa)` 捕获 nvim 的输出/变量，拿到的是空串"
  - "headless nvim 命令后面加了 `2>/dev/null`，结果什么都收不到（失败信号）"
  - "想取 $VIMRUNTIME / stdpath / 某个 vim 变量值，拼进后续 ls、rg 的路径"
  - "把 `nvim --headless` 的输出重定向进文件，文件是空的（失败信号：内容跑去了 stderr）"
  - "要读 nvim 自带 runtime 的文档（doc/api.txt 等），不想猜安装路径"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b29d-0cb6-7097-91f3-80f8d5ba1119
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [nvim-headless-hangs-without-explicit-quit]
---

**主张**：headless nvim 里 `:echo` 和 `lua print` 的输出走 **stderr**，不走 stdout。因此 `RT=$(nvim --headless +'echo $VIMRUNTIME' +qa)`（命令替换只收 stdout）或命令末尾带 `2>/dev/null` 时都会拿到**空串**——看起来像"变量没设/命令没输出"，实际内容一直打在你丢掉的那条流上。要捕获就写 `2>&1`。

**为什么**：headless 模式下 nvim 把消息区（`:echo`、`print` 等）写到 stderr；命令替换 `$(…)` 只捕获 stdout，`2>/dev/null` 更是把答案直接扔掉。空串没有报错、没有非零退出码，于是被当成"这个变量取不到"，去绕别的路。

**怎么修**：
- 捕获输出：`X=$(nvim --headless +'echo $VIMRUNTIME' +qa 2>&1)`；
- 落文件同理：`nvim --headless +'lua print(vim.env.VIMRUNTIME)' +qa 2>out.txt`；
- 只想拿 nvim runtime 里的文件，别解析变量，直接问 nvim：
  `nvim --headless +'lua print(vim.api.nvim_get_runtime_file("doc/api.txt", false)[1])' +qa 2>&1`
  → `/opt/homebrew/Cellar/neovim/0.12.4/share/nvim/runtime/doc/api.txt`；
- 或绕开 nvim：`ls -d /opt/homebrew/Cellar/neovim/*/share/nvim/runtime`。

**证据**（会话 01a0b29d 切片，命令 ↔ 结果）：
- `RT=$(nvim --clean --headless +'echo $VIMRUNTIME' +qa 2>/dev/null); echo "RT=$RT"` → `RT=`（空）。
- 紧接着两条命令拿这个空值拼路径：`rg -n "virt_text_win_col" -B3 -A12 "$RT/doc/api.txt"` → `rg: /doc/api.txt: IO error for operation … (os error 2)`（重复两次，白费两轮）。
- 改用硬编码路径后立刻拿到内容：`rg -n "virt_text_win_col" -B2 -A14 /opt/homebrew/Cellar/neovim/0.12.4/share/nvim/runtime/doc/api.txt` → 命中 `3341- • virt_text_repeat_linebreak …` 等。
- 本机复核（reflector，2026-09-18，nvim 0.12.4）：`nvim --headless +'echo $VIMRUNTIME' +qa 1>/dev/null` → 仍打印 `…/runtime`（⇒ 走 stderr）；同一命令 `2>/dev/null` → 空；`2>&1` → 有路径；`lua print(vim.env.VIMRUNTIME)` 同样只走 stderr；`--clean` 与不加 `--clean` 结果一致（不是 `--clean` 的锅）。

**边界/反例**：本条说的是"输出流分到哪"，不是"命令有没有跑"——退出码仍是 0，所以 `set -e` / `&&` 链不会救你，只有重定向能救。另外别把"headless 一切输出都在 stderr"当普适断言——本条只实测了 `:echo` / `lua print` 这两条消息通道；含 nvim 输出的流水线统一按 `2>&1` 收最省事。
