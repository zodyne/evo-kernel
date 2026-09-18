---
id: backgrounded-cd-and-list-leaves-shell-cwd-unchanged
type: lesson
status: validated
scope: global
domain: shell
tags: [bash, background-job, cwd, relative-path, silent-failure, diagnosis]
triggers:
  - "用 `cd <dir> && <cmd> >> log 2>&1 &` 启动后台任务，紧接着在同一条命令里做诊断（tail 日志 / cat 锁文件 / ./bin/xxx）"
  - "刚启动的后台任务看不到进程、没有锁、tail 日志报 `No such file or directory`（失败信号）"
  - "启动后的探测输出计数为 0 / 空（失败信号），但进程其实在跑"
  - "一条命令前半段明明写了 cd，后半段相对路径却像在别的目录执行"
  - "要在同一条脚本/命令里既启动后台任务又立刻验收它起没起来"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0ae1e-1763-764c-a77e-51771fbd8c10
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [make-nothing-to-be-done-check-cwd]
---

# `cd DIR && CMD &` 里的 `cd` 只作用于后台子 shell，父 shell 的 cwd 不变

**主张**：`cd DIR && CMD >> log 2>&1 &` 会把**整条 `cd … && CMD …` 列表**放进后台子 shell，当前 shell 的工作目录**不变**。于是同一条命令里随后用相对路径做的诊断（`tail ops/log/xxx.log`、`cat ops/log/.lock/pid`、`./bin/evo queue`）会静默读到错误的目录：`No such file or directory`、空输出、计数 0——**看起来像"后台任务没起来 / 没产出"，实际进程已经起来了**。

**证据（2026-09-17 本机，一次真实的误判）**：
- 启动语句 `cd /Users/zodyne/Dev/evo-kernel && EVO_DISTILL_TIMEOUT=1800 setsid nohup ./ops/bin/evo-distill.sh --max 200 >> ops/log/distill-runner.out 2>&1 < /dev/null &` 之后，同一条命令的探测输出是 `=== 日志尾 === tail: ops/log/distill.log: No such file or directory === 当前队列 === 0`。
- 但同一会话对同一文件的读取此前一直正常，队列规模是 148 / 159，不是 0。
- 随后 `echo "cwd=$(pwd)"` 打印 `cwd=/Users/zodyne/Dev/spc865-adc` —— 证明那条 `cd` 从未作用于当前 shell（会话是在另一个项目目录里起的）。
- 真值来自 `pgrep -fl "evo-distill"`：`9611 /bin/bash -c cd /Users/zodyne/Dev/evo-kernel && EVO_DISTILL_TIMEOUT=1800 nohup ./ops/bin/evo-distill.sh --max 200 >` —— 进程确实在跑。
- 本机复现同一 shell 语义：`cd /Users/zodyne/Dev/evo-kernel && /bin/bash -c 'cd /tmp && sleep 3 & echo "父 shell cwd=$(pwd)"'` → `父 shell cwd=/Users/zodyne/Dev/evo-kernel`。

**做法**：启动与验收分两步。① 单独一条语句 `cd DIR`，或对命令用绝对路径；② 验收/诊断一律用绝对路径，或先 `pwd` 自检。既要保留 cd 语义又要后台，用显式子 shell 包裹：`(cd DIR && CMD >> log 2>&1) &`。

**边界**：`&` 只背景化它左侧的那条 and-list。写成 `cd DIR; CMD &`（分号）时 cd 会正常作用于当前 shell；写成 `cd DIR && CMD &` 才会踩这个坑。
