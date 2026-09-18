---
id: grep-alternation-count-cannot-prove-single-pattern-present
type: lesson
status: validated
scope: global
domain: verification
tags: [grep, ripgrep, counting, false-positive, verification]
triggers:
  - "用 grep -c / rg -c 'A|B' 的计数当『A 出现了』的证据"
  - "要确认某个字符串/终止标记是否出现在文件里，却把多个模式合并成一个交替式去数"
  - "计数对上了（=1）但没看命中的到底是哪一行（失败信号）"
  - "核验日志/产物完整性、跑没跑完时统计模式命中数"
  - "写检查脚本，用一条联合正则同时探测多种信号并只看总数"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7ad-67d6-725c-a75a-f9894a03787a
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [nvim-startuptime-missing-started-marker-truncated-capture, checker-positive-control-or-negative-void]
---

# `rg -c 'A|B'` 的计数不能证明 A 存在——计数可能全部来自 B

**主张**：用联合交替式计数（`rg -c 'A|B'`）做存在性判断是无效的：`-c` 只数**匹配行**，交替式里任一分支命中都算，于是"A 是否存在"被 B 的命中掩盖。要判定 A 出现，必须用只含 A 的模式（`rg -n 'A'`），或分两次各数各的；想按匹配次数而非行数计，用 `rg -o 'A' file | wc -l`。

**为什么**：`-c` 的语义是"匹配的行数"，不是"每个分支各命中多少"，它把多分支的结果压成一个数，丢掉了唯一能区分分支的信息。当 A 是 B 的子串或两者共处一行时，这个计数**永远**无法回答"A 在不在"，却给出一个看起来很肯定的非零值。

**证据（本会话命令对照）**：
- `rg -c 'NVIM STARTED|--- NVIM' /tmp/nvim_st.txt` → `1`：这个 `1` 被当作"STARTED 标记存在"；
- 换成逐行输出才看清命中的是哪个分支：`rg -n 'NVIM STARTED|--- NVIM' /tmp/nvim_st.txt` → `7:000.000  000.000: --- NVIM STARTING ---`（全文仅此一行，`wc -l` = 239）。即那个 `1` 完全来自 `--- NVIM` 这个宽分支，`NVIM STARTED` 一次都没出现——该文件其实是截断产物（见 related）。
- 这正是"抽查引用/核验产物"时最容易滑过去的假阳性：命令有输出、计数非零、退出码 0。

**边界 / 反例**：
- 只想知道"这两者任一出现过没有"时，交替式计数是对的用法——错只错在把它当成单分支的存在性证明；
- 反过来，计数为 0 时结论是可靠的（A、B 都没出现），假阳性只发生在非零一侧；
- 更稳的习惯：存在性检查一律 `rg -n`（要行号）或 `rg -o | wc -l`（要次数），不要用 `-c` + 交替式下判断。

**失败信号（未来命中即该想起本条）**：写下的检查是 `... -c 'X|Y'` 且准备据其结果断言 X → 立刻换成只含 X 的模式重跑。
