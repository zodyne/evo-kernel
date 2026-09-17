---
id: 2026-09-16-bash-guard-blocks-pathless-recursive-scan
type: lesson
status: validated
scope: global
domain: pi-harness
tags: [pi, bash-guard, grep, rg]
triggers:
  - "在 pi 里跑 grep -r 或无路径递归扫描被 bash-guard 硬拦"
  - "命令被 '递归扫描代价失控' 拦截"
  - "cwd 在家目录树里想扫全盘，命令被 bash-guard 拦下"
  - "批量找文件/查内容却触发 bash-guard 拦截"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a7f9-4ced-73b3-8cfc-3829cc92108c
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [substring-matcher-cannot-tell-exec-from-mention]
---

pi 的 bash-guard 扩展会硬拦「无路径递归扫描」——当 cwd 在家目录树里，无路径限制的递归 grep 等于全盘扫描（实测 ~/Dev = 48.8GB / 142,099 文件，单线程 grep 18–50 MB/s），直接返回「递归扫描代价失控」拦截信息；本会话两次触发（一次 for 循环扫 Group Containers、一次 docker diff 管道）。

为什么：这是 bash-guard 的代价失控保护，不是命令本身语法错；探测类命令应改用内置 grep/find 工具（走 ripgrep、限定 cwd），或命令行用 `rg` 并排除数据目录（~/Dev 下的 .bin/.mat/.mp4 是几十 G 雷达数据）。

边界/反例：探测命令的非零退出会被记进回合摘要 failed，末尾补 `|| true` 或改内置工具；真正的构建/测试失败不要吞退出码。
