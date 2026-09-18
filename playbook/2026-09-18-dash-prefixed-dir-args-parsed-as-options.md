---
id: dash-prefixed-dir-args-parsed-as-options
type: lesson
status: validated
scope: global
domain: shell
tags: [shell, glob, macos, bsd, cli, session-dir]
triggers:
  - "用 ls -d */ 或 for d in */; do find \"$d\" ... 批量列/数目录，而目录名以 -- 开头"
  - "ls 报 unrecognized option `--xxx--/'，或 find 报 illegal option -- -（失败信号）"
  - "通配符展开出的操作数以短横线开头，被命令当成选项解析"
  - "同一个 for 循环手工加 ./ 前缀后就正常了（失败信号：参数前缀问题而非命令写错）"
  - "要在一个名字以 - 开头的目录/文件上跑批量命令"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7aa-e662-725c-a75a-f9843c02cafa
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [2026-07-27-zsh-unquoted-glob-arg-no-matches]
---

主张：`*/` 展开出的操作数如果名字本身以 `-` 开头，CLI 会把它当**选项**解析——`ls -d */` 报
`ls: unrecognized option `--private-tmp--/'`，`find "$d"` 报 `find: illegal option -- -`，整条命令零输出。
把每个操作数加上 `./` 前缀即可（`for d in ./*/; do find "./$d" ...`）——pi 的会话目录名由 cwd 派生
（`--Users-zodyne--/`、`--private-tmp--/`），天然带 `--` 前缀，所以数会话文件/扫日志目录时必踩。

**为什么**：给变量加引号（`"$d"`）只防分词，不改"操作数以短横线开头"这一事实；选项解析在命令内部按参数首字符判定。
macOS/BSD 用户态（ls/find）对未知选项是硬报错，不是静默忽略——所以命令"跑了但什么都没输出"。

**证据（本会话命令 ↔ 结果）**：
- `cd /Users/zodyne/.pi/agent/sessions && ls -d */ | head -30 && echo "---TOTAL---" && find . -name '*.jsonl' | wc -l`
  → `ls: unrecognized option `--private-tmp--/' usage: ls [-@ABCFGHILOPRSTUWXabcdefghiklmnopqrstuvwxy1%,]`（整条链在第一步断掉，TOTAL 没算出来）。
- `for d in */; do n=$(find "$d" -name '*.jsonl' | wc -l | tr -d ' '); echo "$n  $d"; done`
  → `find: illegal option -- - usage: find [-H | -L | -P] [-EXdsx] [-f path] path ... [expression]`（带引号同样失败）。
- `for d in ./*/; do n=$(find "./$d" -name '*.jsonl' | wc -l | tr -d ' '); echo "$n  $d"; done`
  → `10  ./--private-tmp--/ 3  ./--private-tmp-auto-smoke--/ 1  ./--private-tmp-bashguard-e2e--/ 17  ./--private-tmp-claude-5…`（加 `./` 前缀后正常）。
- 同会话后续 `ls --  ./--Users-zodyne--/ | head -3` → 正常列出会话文件（`--` 作为选项终止符也可修复 ls 一侧）。

**边界/反例**：只在**操作数本身**以 `-` 开头时触发；glob 展开出的名字都是普通名字时 `ls -d */` 正常，别把这条当成"glob 不能用"。
修复优先 `./` 前缀：`ls` 与 `find` 都吃，且可移植；`--` 只在实现了选项终止符的命令上可靠（本会话验证了 `ls`；`find` 的路径参数用 `./` 前缀或用法里列出的 `-f path` 形式）。
未在 GNU coreutils 上复验（本会话证据全部来自 macOS/BSD 用户态）。

**失败信号（未来命中即该想起本条）**：`unrecognized option` 后面跟着一个看起来像目录名的东西；或 `illegal option -- -` 这种缺了选项名的报错。
