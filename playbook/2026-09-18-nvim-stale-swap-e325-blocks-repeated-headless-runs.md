---
id: nvim-stale-swap-e325-blocks-repeated-headless-runs
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, swap, e325, w325, headless, test-harness, state-dir]
triggers:
  - "反复起停 nvim（headless 测试、探针脚本、被 kill 的实例）后，下一次打开同一文件报 E325: ATTENTION Found a swap file"
  - "自动化渲染/插件测试跑到一半中断，看输出才发现是 swap 文件（失败信号：报错发生在插件逻辑之前）"
  - "看到 W325: Ignoring swapfile from Nvim process <pid>，不确定要不要处理"
  - "`~/.local/state/nvim/swap/` 下一堆 `%private%…` 名字，想对应回是哪个文件"
  - "批量 nvim 测试要保证每次干净启动"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b29d-0cb6-7097-91f3-80f8d5ba1119
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [nvim-headless-hangs-without-explicit-quit]
---

**主张**：反复起停（尤其被 kill）的 nvim 会把 swap 留在 `~/.local/state/nvim/swap/`，文件名是**按绝对路径 URL 编码**的（`/tmp/mdtest/wide.md` → `%private%tmp%mdtest%wide.md.swp`，同一文件的第二个 swap 是 `.swo`）。下一次用同一文件启动时 nvim 直接 **E325 中断**，错误信息出现在插件/脚本逻辑之前，很容易被误读成"测试脚本坏了"。跑批前先看并清掉这些残留即可。

**怎么修**：
- 清点：`ls ~/.local/state/nvim/swap/`（名字编码过，不能靠拼路径找）；
- 清理：`rm -f ~/.local/state/nvim/swap/*<文件名>.sw*`（**`.sw*` 而不是 `.swp`**——同一文件可能同时有 `.swp` 和 `.swo`；本会话删掉 `.swp` 后目录里仍有 `%private%tmp%mdtest%wide.md.swo`）；
- 收尾确认：本会话最后专门核对过"测试 swap 已清理"。

**W325 与 E325 要分开看**（本会话两条都出现过）：
- `W325: Ignoring swapfile from Nvim process 82380` —— swap 的持有者**还活着**（82380 正是用户正在用的实例，它开着 PLAN.md），nvim 自己判定并忽略、继续启动，只是警告，**不要去删**；
- `E325: ATTENTION Found a swap file …` —— 本次真的被拦住，需要处理（本会话这条对应的是被 kill 掉的 headless 测试实例留下的 `wide.md.swp`）。

**证据**（会话 01a0b29d 切片，命令 ↔ 结果）：
- 失败：`PLUGIN_OLD=1 MDTEST_VARIANT=bench_cellwrap nvim --headless -u /tmp/mdtest/bench_ui.lua /tmp/mdtest/wide.md "+lua print('ft='..vim.bo…` → `E325: ATTENTION Found a swap file by the name "~/.local/state/nvim/swap/%private%tmp%mdtest%wide.md.swp"`。
- 清理与残留：`rm -f ~/.local/state/nvim/swap/*wide.md.swp 2>/dev/null; ls ~/.local/state/nvim/swap/ | head` → 仍列出 `%private%tmp%mdtest%wide.md.swo`、`%Users%zodyne%Dev%algommw-plus%PLAN.md.swp` 等（前者是同一文件的第二份 swap，后者属于活着的用户实例）。
- 活实例的警告（对照）：同目录另一个 headless 探针（`cat > dbg.lua …`，切片里命令尾被截断）→ `enabled= trueW325: Ignoring swapfile from Nvim process 82380 ft=  wins= 1 bufs= 1 …`（82380 = 用户正在用的实例）。
- 清理后继续跑：后续同类 headless 渲染/基准命令均正常产出结果，末尾 `tmux -L … ls` 检查输出 `(无输出=测试 tmux server 已清)` + `测试 swap 已清理`。

**边界/反例**：文件名的 URL 编码（`%private%tmp%…`）只说明路径怎么编码，**不能**从中反推是哪个进程留下的；判断该不该删要回到 W325/E325 或者 `ps` 看 pid。删活实例的 swap 有丢未保存改动的风险，别把"清 swap"写成无脑 `rm -f ~/.local/state/nvim/swap/*`。
