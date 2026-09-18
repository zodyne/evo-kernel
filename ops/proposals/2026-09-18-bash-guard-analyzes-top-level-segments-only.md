---
id: bash-guard-analyzes-top-level-segments-only
type: lesson
status: candidate
scope: global
domain: pi-harness
tags: [pi, bash-guard, cwd, nested-shell, static-analysis]
triggers:
  - "同一条 grep 在顶层被 bash-guard 拦下，包进 /bin/bash -c '…' 却能跑，想解释差异"
  - "命令里已经 cd 到项目目录，bash-guard 仍按家目录 cwd 判『递归扫描代价失控』"
  - "拦截文案写『无路径递归 grep』，但命令既没 -r 也带了显式文件路径（失败信号：文案与命令形态不符）"
  - "想确认 bash-guard 的静态分析范围：解析哪些片段、cwd 取哪一个"
  - "担子把长扫描包进嵌套 shell 后绕过了代价保护"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-52aa-73b1-bdd8-c2d3487bea9e
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [bash-guard-blocks-nonrecursive-grep-cwd-home, 2026-09-16-bash-guard-blocks-pathless-recursive-scan]
---
**主张**：pi 的 bash-guard 只对**顶层命令片段**做静态分析，而且判定用的 cwd 是 **tool call 的初始 cwd（会话启动目录）**，不是命令执行到该片段时的实际目录 —— 所以：

1. `cd /Users/zodyne/Dev/evo-kernel && grep -n <pat> /tmp/cat.tsv` 里虽然 `cd` 到了项目目录，grep 片段仍被按「cwd = 家目录」判成「无路径递归 grep」硬拦；
2. 把同一段命令包进 `/bin/bash -c '…'` 后，守卫不解析嵌套 shell 的内容，命令直接放行、输出真实结果。

**为什么**（读实现 + 实测一致）：`~/.pi/agent/extensions/bash-guard/index.ts` 的入口是 `inspectBash(command, timeout, cwd, home)`：先 `splitSegments(command)` 切顶层片段，再逐段 `analyzeSegment()`；`cwd` 全程用调用方传入的那一个，`cd` 不在分析范围里，而嵌套 shell 的字符串整体是一个普通参数，里面的 grep/find 不会被识别成工具。

**证据**（会话 01a0b2ce 切片，命令↔结果）：
- 顶层三次被同一句文案拦下，其中两次带**显式文件路径且非递归**：`cd /Users/zodyne/Dev/evo-kernel && grep -n "bash-guard" /tmp/cat.tsv | cut -c1-200` → `✗ bash-guard 拦截：递归扫描代价失控 —— 无路径递归 grep，而 cwd 在家目录树里（等于全盘）…`；
- 先 `pwd` 确认 tool call 的初始 cwd 是家目录：`$ pwd; echo "---"; cd /Users/zodyne/Dev/evo-kernel && /bin/bash -c 'pwd; grep -n bash /tmp/cat.tsv | head -3'` → `/Users/zodyne` / `/Users/zodyne/Dev/evo-kernel` / 真实命中行（`5:2026-07-27-zsh-unquoted-glob-arg-no-matches…`）；
- 该会话后续多次用 `… | /bin/bash -c 'cat'` / `/bin/bash -c 'grep …'` 取数均通过。

**边界/反例**：
- 嵌套 `bash -c` 只是绕过了**静态分析**，不代表扫描真的便宜：真正的大范围扫描仍应改用内置 grep 工具或 `rg` 并限定子树（见 related 两条）；把长扫描藏进嵌套 shell 会同时绕开代价保护。
- 本条解释的是「为什么 `cd` 到项目目录没用」和「为什么嵌一层就放行」；「cwd 在家目录时连非递归、带路径、管道的 grep 都被拦」这一误报形态见 `bash-guard-blocks-nonrecursive-grep-cwd-home`。
