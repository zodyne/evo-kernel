---
id: nvim-tty-probe-more-pager-blocks
type: lesson
status: validated
scope: global
domain: nvim
tags: [nvim, tmux, pty, more, pager, probe-script, hang]
triggers:
  - "在 tmux/真实 TTY 里（非 --headless）跑 nvim 探针脚本，脚本该写的报告文件一直没生成（失败信号）"
  - "探针脚本会打印多行 message / vim.inspect 出来的配置表，屏幕停在半屏输出不动"
  - "同脚本在 --headless 下能跑完，换到 TTY 里就没产物"
  - "写最小 init（mininit.lua）复现 nvim 显示类问题"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b351-8a08-7097-91f3-80fbeb2387b2
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [nvim-headless-hangs-without-explicit-quit]
---

# 真实 TTY 里跑 nvim 探针：多行 message 触发 `-- More --` 分页会把脚本卡死，报告文件不生成；`vim.o.more = false` 解决

## 主张

用真实 TTY（tmux pane）跑 nvim 探针脚本、靠「写文件」回传结果时，脚本打印的多行 message（如 `vim.inspect(config)` 这种多行配置表）会触发 `more` 分页等待 `-- More --`，脚本停在那一行等按键，**后面的写文件永远不发生**；外部只看到「报告文件不存在」，没有任何错误。探针用的最小 init 里加 `vim.o.more = false` 即跑完并产出报告。

## 证据（切片命令↔结果：同一份 mininit.lua，只差这一行）

- 加之前：`$ ... tmux -L nvimprobe new-session -d -s minon -x 150 -y 45 'PROBE_WRAP=1 /bin/sh /tmp/nvim-probe/run-min.sh'`
  ↳ `✗ ls: min-report-*.txt: No such file or directory`（run-min.sh 的产物一个都没有）
  同一时刻抓屏只见多行 message 铺在屏幕上（`min-on-screen.txt`：`1 w= 1 |{|  2 w= 18 |  anti_conceal = {|  3 w= 14 |    ignore = {|  4 w= 25 |      table...`）。
- 加之后：往 mininit.lua 插入 `vim.o.more = false`（grep 回显 `42:vim.o.more = false`），重跑同一探针
  ↳ `=== report wrap=1 === PROBE_WRAP=1 resolved_wrap=true win_wrap=true conceallevel=2 line  1 bufw=25...`（报告文件出现，探针跑完）。

## 反例 / 边界

- `--headless` 下没有分页，所以这个坑只在「为了看真实渲染必须起 TTY」时才出现：headless 能跑完 ≠ TTY 里能跑完。症状（不返回 / 无产物）与 nvim-headless-hangs-without-explicit-quit 相同但成因不同——那条是没显式退出，这条是被分页挡住。
- 等价修法：探针输出改走文件或 `io.stderr`（不经过 message 层），或启动加 `-c 'set nomore'`。
- 失败信号识别顺序：TTY 里 nvim 探针无产物 + 屏幕停在半屏多行输出 → 先怀疑 more，别先怀疑脚本逻辑或 tmux 键位。
