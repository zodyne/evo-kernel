---
id: bash-guard-blocks-nonrecursive-grep-cwd-home
type: lesson
status: candidate
scope: global
domain: pi-harness
tags: [pi, bash-guard, grep, rg, false-positive, cwd]
triggers:
  - "cwd 在家目录（或家目录的祖先）时，明明带了文件路径的 grep 也被 bash-guard 拦下"
  - "管道里的 grep（如 ifconfig | grep inet）触发『无路径递归 grep』拦截文案"
  - "拦截理由写『无路径递归 grep』，但命令既没 -r 也没在读文件（失败信号：文案与命令形态不符）"
  - "从家目录 cwd 探测系统/配置文件内容，想找一次就能通过的写法"
  - "改了 grep 写法仍被同一句文案挡住，怀疑是守卫解析而不是命令本身的问题"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0aa46-842a-765e-9e51-00867512a904
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [2026-09-16-bash-guard-blocks-pathless-recursive-scan]
---

一句话主张：当 cwd 是家目录（或家目录的祖先）时，pi 的 bash-guard 会拦掉**任何**含 grep 的片段——不只是无路径的递归 grep，还包括没写 `-r` 的非递归 grep、带着显式文件路径的 `grep -i pat /etc/hosts`，以及纯 stdin 管道的 `ifconfig | grep inet`；拦截文案一律是『无路径递归 grep，而 cwd 在家目录树里（等于全盘）』，与命令实际形态不符。此时最省事的通过写法是把 grep 换成 `rg` 并显式列出文件（`for f in ...; do rg -i pat "$f"; done`）——本条会话就是这样立刻通过的。

**为什么**（读代码得到的机制，不是猜测）：`~/.pi/agent/extensions/bash-guard/index.ts` 的 `analyzeSegment()` 里，`grepPaths.push(...)` 与 `grepHasPath = ...` 两行写在 `if (!isRecursive(rest)) continue;`（index.ts:217）**之后**，所以非递归 grep 永远走不到那两行、`grepHasPath` 保持 false；随后 index.ts:259 的兜底判定 `a.tools.some(GREP_FAMILY) && !a.grepHasPath && (cwd === home || home.startsWith(cwd + sep))` 只问「有没有 grep 工具 + 有没有路径」，**不看递归旗标**，于是「非递归但带路径」和「纯管道」两种形态一起被算成了无路径递归。

**证据**（会话 01a0aa46，会话头部 cwd=`/Users/zodyne`，即家目录本身）：
- 两次拦截，文案完全相同（`bash-guard 拦截：递归扫描代价失控 —— 无路径递归 grep，而 cwd 在家目录树里（等于全盘）`）：
  - `ifconfig | grep -A3 "en0\|en1" | grep "inet " || true` —— 两个 grep 都从管道读 stdin，不碰文件系统；
  - `grep -i "<lan-host>\|x13" /etc/hosts …`（同一条命令里后两个 grep 同样带路径：`~/.ssh/config`、`~/.ssh/known_hosts`）—— 三次调用都有显式文件路径、都不带 `-r`。
- 改为显式文件 + `rg` 后一次通过：`for f in /etc/hosts ~/.ssh/config ~/.ssh/known_hosts; do … rg -i "192\.168\.2\.105|x13" "$f" …; done` → 输出三行 `(无匹配)`。
- 本机复现（该扩展文件自 2026-09-14 起未改动，`node selftest.mjs` 15/15 通过）：`inspectBash('grep -i "pat" /etc/hosts', undefined, HOME, HOME)` → `block`；同一条命令把 cwd 换成项目目录 → `allow`；`for f in …; do rg …; done` + cwd=HOME → `allow`。
- 现成 selftest 覆盖不到这一档：它的「非递归 grep」放行用例 cwd 用的是项目目录（`/Users/zodyne/Dev/algommw`），没有 cwd=家目录的非递归用例。

**边界**：触发条件是 cwd 的位置（家目录本身或其祖先），不是命令形状——同一条非递归 grep 在项目 cwd 下放行；`rg` 不受这条判定影响。递归 grep 扫家目录子树被拦（如 `grep -rn pat ~/Dev`）属于原本的代价保护，是另一档，见 related 条目。若要修这个误报，方向是让兜底判定也要求 `sawRecursive`（或把路径收集移到 `isRecursive` 判断之前）。
