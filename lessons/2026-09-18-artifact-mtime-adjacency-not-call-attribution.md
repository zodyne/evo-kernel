---
id: artifact-mtime-adjacency-not-call-attribution
type: lesson
status: candidate
scope: global
domain: session-forensics
tags: [pi, toolCallId, mtime, timeline, crash-forensics, attribution]
triggers:
  - "会话/进程崩溃后要判断末条 toolCall 到底跑没跑（该调用没有配对 toolResult）"
  - "把产物 mtime 与『最近一次调用』时间相邻直接算成归属"
  - "要在 transcript 与文件系统之间重建『命令发出 → 产物落盘』的时间线"
  - "报告里写『末条命令没有结果，所以它没执行』（失败信号）"
  - "手上只有一条无结果的调用 + 一个 mtime 相邻的产物，就想据此定性（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e5b0-725c-a75a-f97e671dc5aa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [pi-jsonl-toolresult-toolcallid-pairing, pi-session-file-utc-name-vs-local-mtime, shared-state-log-not-instance-evidence, nvim-startuptime-missing-started-marker-truncated-capture]
---

# 产物 mtime 与调用时刻『时间相邻』不等于该调用写了它：无配对 toolResult 的那一跳不能靠相邻自证

## 主张

崩溃会话里某条 toolCall 没有配对 toolResult，只说明**结果没写回 transcript**，不能推出"命令没执行"；反过来，**也不能用"产物 mtime 离它最近"推出"它执行了并写了这个产物"**。产物归属要锚在**命令内容**上（这条命令的参数里写的就是这个路径），时间相邻只作为辅助；相邻也可能属于前一条**有结果**的调用。定性前至少要做三件事：①按 id 配对找出无结果的那一跳；②取到那一跳的**完整命令行**；③确认候选产物唯一由该命令写出（无第二个写者）。

## 为什么

崩溃时 transcript 与文件系统是两条不同源的记录：控制流（谁调用了什么）在 transcript 里，副作用（谁写了什么）在文件系统里。中断点附近的调用会挤在一起（本例相邻调用只差 3 秒），而产物 mtime 只给一个时刻，不给写者身份——两条证据不交叉就存在多解：产物可能是上一跳（有结果的那条）写的，也可能是无结果那一跳写的，甚至可能是会话外的进程写的（用户手敲、另一个实例）。按"时间最近"归因，就是把多解当成唯一解写进根因。

## 证据（本会话命令 ↔ 结果，切片逐字）

- 配对计数显示**有一跳没回来**：`… echo -n "toolCalls: "; jq -r …` → `toolCalls: 27 toolResults: 26 === any trace of the final call id === 1 ust run nvim directly with the tool's`（末条调用的 id 在全文中只有 1 处痕迹，且那处是 assistant 正文的复述，不是结果记录）。
- 但**上一条调用是有结果的**：`… echo "=== 08:48:35 assistant (previous, verbatim toolCall args) ===" …` → `… call_00_GH3r5WLjHSGxsPkYxJd19941 {"command":"cd ~/.config/`（切片 120 字截断）；同一 id 在别处的结果记录：`##### call_00_GH3r5WLjHSGxsPkYxJd19941 at 1789375715460 err=false [{"type":"text","text":"=== load config headless, capt`（`1789375715460` ms = `2026-09-14T08:48:35Z`）。
- 候选产物的 mtime 恰好贴着**这一条（有结果的）**调用：`ls -laT /tmp/nvim_st.txt /tmp/st.txt …` → `ls: /tmp/st.txt: No such file or directory`、`-rw-r--r--@ 1 zodyne wheel 16386 Sep 14 16:48:38 2026 /tmp/nvim_st.txt`。本机时区可在同一份切片内交叉验证（sessions 目录 mtime `Sep 16 08:43` 对会话文件名 `2026-09-16T00-43-10-128Z…jsonl` ⇒ CST=UTC+8），故 `16:48:38 CST = 08:48:38Z`——比那条**有结果**的调用发出时刻晚 3 秒。
- 产物本身只提供"跑到哪一步"，不提供"谁写的"：`wc -lc /tmp/nvim_st.txt; tail -c 80 … | xxd` → `239 16386 /tmp/nvim_st.txt`；`tail -20 … | cat -v` → 尾部 `024.791  000.050  000.050: require('vim.lsp._transport') 024.794  000…`（启动日志止于 ~24.8 ms）。

## 反例 / 边界

- **本条不主张"末条调用没执行"**——切片里无从判定（该调用的参数在被打印进结果时截断在 120 字，看不到它写不写 `/tmp/nvim_st.txt`）；只主张"时间相邻定不了归属"。
- 能闭环的情形：命令参数里**明确写着唯一的目标路径**（如 `--startuptime /tmp/nvim_st.txt`）、该路径无第二个写者、且 mtime 落在调用之后。三者缺一就只能写"疑似"。
- **反向也不成立**：有配对 toolResult ≠ 命令成功；没配对 ≠ 命令失败（中断可能发生在返回途中）。
- 共享日志/多实例场景另有一层归属陷阱（同一份日志里的一行不能证明是哪个实例产生的），判据见 related。

## 失败信号（未来命中即该想起本条）

- 结论里出现"末条命令没有配对结果，所以它没执行"。
- 结论里出现"产物时间是 X，紧接着末条调用，所以是它写的"——先把那条调用的**完整命令行**取出来看路径。
- 无结果那一跳的行参数只在截断窗口里可见就敢定性（先想办法取原文）。
