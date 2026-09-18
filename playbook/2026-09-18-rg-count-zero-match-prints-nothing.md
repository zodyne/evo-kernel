---
id: rg-count-zero-match-prints-nothing
type: lesson
status: validated
scope: global
domain: shell
tags: [ripgrep, rg, grep, shell, exit-code, counting]
triggers:
  - "在脚本里用 `n=$(rg -c PAT file)` 取命中数，零匹配时变量为空"
  - "`rg -c` 的结果拿去算 `$(( ))` 或 `[ \"$n\" -gt 0 ]`，报 integer expression expected（失败信号）"
  - "按 grep -c 的习惯以为零匹配会打印 0，直接读 rg -c 的 stdout 当计数"
  - "统计日志/产物里某标记的条数，零命中时脚本静默走错分支或报语法错"
  - "管道里 rg 零命中 exit 1 把 `&&` 链 / `set -e` 脚本短路（失败信号）"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-52eb-73b1-bdd8-c2d41b3df10d
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [grep-alternation-count-cannot-prove-single-pattern-present, rg-capital-e-is-encoding-not-extended-regex]
---

一句话主张：`rg -c` 在**零匹配**时不打印任何数字（stdout 为空）并返回 exit 1，只有加 `--include-zero` 才会打印 `0`；于是 `n=$(rg -c PAT file)` 在零命中时得到空串，把它当计数用（算术展开、`-eq`/`-gt` 比较、`printf %d`）会报错或走错分支。`grep -c` 一定打印 `0`，两者不能在"读 stdout 取计数"这件事上互替。

**为什么**：ripgrep 的 `-c` 默认省略零匹配的计数行，同时沿用"无匹配即 exit 1"的退出码；grep 的 `-c` 零匹配时 stdout 也有 `0`。脚本通常只读 stdout，于是同一个"计数"在两个工具下一个是 `0`、一个是空串。

**怎么修**：
- `n=$(rg -c PAT file || true); n=${n:-0}` —— 兜底成 0；
- 或 `rg -c --include-zero PAT file`（零匹配打印 0，退出码仍为 1）；
- 要与 grep 行为完全一致就继续用 `grep -c`；要按匹配**次数**而非**行数**计用 `rg -o PAT file | wc -l`。

**边界/反例**：`grep -c` 零匹配的退出码同样是 1，所以在 `set -e` 或 `&&` 链里一样会被短路——差异只在 stdout（`0` vs 空）。另外 `rg -c` 数的是匹配**行**数、不是匹配**次数**，交替式 `'A|B'` 的计数不能证明 A 出现（见 related）。

**证据**（会话 01a0b2ce 切片，命令↔结果）：
- `printf 'hello\nworld\n' | rg -c 'hello|WORLD_NOPE'` → 打印 `1`；
- `printf 'hello\n' | rg -c 'WORLD_NOPE'` → **无输出**，随后 `echo "rg_rc=$?"` → `rg_rc=1`。

（reflector 本机复核、同一台机器：`printf 'hello\n' | rg -c 'WORLD_NOPE'` → stdout 空、rc=1；加 `--include-zero` → 打印 `0`、rc=1；`grep -c` → 打印 `0`、rc=1。算术展开实测得到空串而非 0。）
