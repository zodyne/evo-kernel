---
id: bash-guard-block-skips-whole-command
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, bash-guard, compound-command, side-effect]
triggers:
  - "把准备步骤（rm -rf / mkdir / 重定向写文件）和 grep/rg 扫描写在同一条复合命令里，扫描片段被 bash-guard 拦下"
  - "上一条命令被 bash-guard 拦过之后，下一条命令报 No such file or directory / 目录不存在，先怀疑 mkdir 或写盘失败（失败信号）"
  - "被拦的命令里含 rm -rf 或覆盖写，担心它其实已经执行了一半（同一条命令里既有 cd/mkdir/写文件，又有无路径递归扫描）"
  - "重试一条曾被 bash-guard 拦截的长复合命令，想只补跑被拦的扫描段"
created: 2026-09-18
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b2ce-5368-73b1-bdd8-c2d88804e74e
last_verified: 2026-09-18
superseded_by: null
schema_version: 1
related: [2026-09-16-bash-guard-blocks-pathless-recursive-scan, bash-guard-analyzes-top-level-segments-only, bash-guard-blocks-nonrecursive-grep-cwd-home]
---

**主张**：bash-guard 的拦截以**整条命令**为单位、发生在执行之前——被拦的命令任何一段都不会跑，包括命令头部的 `cd` / `rm -rf` / `mkdir` / 重定向写文件。因此被拦之后，下一条依赖这些准备步骤的命令会报「目录/文件不存在」，那不是 mkdir 或写盘失败，而是准备步骤压根没执行；重试时要把准备步骤和被拦的扫描段作为一个整体重跑（或干脆拆成两条命令）。

**为什么**：拦截是 hook 在命令交给 shell 之前的静态判定，返回拦截文案即整条 reject，shell 根本没被启动；「拦截输出里只提扫描」只是拦截**理由**，不代表命令的前半段已经生效。

**证据**（session 01a0b2ce 切片，命令 ↔ 结果）：
- 一条复合命令（切片显示为 `cd /tmp && rm -rf rectest && mkdir rectest && cd rectest && printf 'CONST=1\nclass A:\n    def m(self):\n        pass\ndef f():\n    pass\n' > mod.py`，触发拦截的扫描片段在切片截断掉的部分）→ `✗ bash-guard 拦截：递归扫描代价失控 —— 无路径递归 grep，而 cwd 在家目录树里（等于全盘）`。
- 稍后：`cd /tmp/rectest && rg -n '^(class|def) ' mod.py; echo "rc=$?"` → `rc=1` + `/bin/bash: line 0: cd: /tmp/rectest: No such file or directory`——被拦命令里的 `mkdir rectest` 没有生效，目录不存在。
- 同一探针重跑后才有输出：`cd /tmp/rectest && rg -n '^(class |def )' mod.py` → `4:class A: 9:def f(): rc=0`；切片「写/改文件」区记录 `/tmp/rectest/mod.py` 最终存在，即它是重试后生成的，不是被拦那条命令留下的。

**反例 / 边界**：
- 反向推论别搞错：被拦 ⇒ 整条没执行 ⇒ **没有**半执行的残留要清理；这条讲的是「以为跑了其实没跑」，与 `heredoc-in-and-chain` 那类「命令链一半执行一半没执行」的坑方向相反。
- 拦截文案只提扫描理由（如「无路径递归 grep」），容易让人以为前半段已跑完、只丢了扫描结果；用文件是否存在、退出码核对准备步骤是否生效，别凭拦截文案推断执行进度。
- 本条是拦截的通用效果，与拦的是哪一档扫描无关；拦的成因与绕法见 related 三条。
- 反过来，准备步骤与被拦扫描拆开后，被拦的那条仍是「零执行」，不会产生半成品文件。
