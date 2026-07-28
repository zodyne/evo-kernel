---
id: doc-selfreported-counts-drift
type: lesson
status: validated
scope: global
domain: documentation
tags: [stale-docs, verification, manual]
triggers:
  - "更新手册/README/设计文档里描述系统现状的章节"
  - "写系统进度评估或能力清单"
  - "文档里写着命令数/测试数/条目数这类自述数字"
  - "接手一份几天前构建的文档，不确定内容是否还准"
  - "照文档描述回答'系统有哪些能力'"
created: 2026-07-28
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:dc63fb24-b5f6-455e-87c6-6bfc029de1eb
last_verified: 2026-07-28
superseded_by: null
schema_version: 1
---

文档里**自述的能力数字**（命令数、测试断言数、条目数、调用次数）漂移得比正文快得多。改这类文档前必须实跑命令取当前值，不能沿用文档自述——包括不能沿用文档里"已经修正过"的注释。

硬证据（Evo-Kernel，2026-07-28）：`docs/user-manual.tex` 构建于 07-24，4 天内仓库有 56 次提交。文档写"evo CLI 21 个命令"实际 26（`evo --help`）；写"smoke 必须 PASS=61"实际 85（`doctor --full`）；写"现在 recall 才约 50 次"实际 162（`evo reflect`）。更说明问题的是 `README.md` 里那句手写修正"§2 命令契约卡（当时 21 个，现 25）"——**连修正本身都已过期**（实为 26）。

为什么特别容易踩：这类数字读起来像稳定事实，不像 HEAD 指针那样显然会变，所以不会主动去核。而它们恰恰绑在最活跃的代码面上。

做法：动文档前先跑一遍取数命令（本项目为 `evo --help` / `evo doctor --full` / `evo reflect` / `git log --since=<文档构建日>`），并在文档里注明取数日期与复现命令，让下一个人能一条命令验伪。

边界：与 [[nav-doc-pinned-head-goes-stale]] 相邻但不同——那条讲手写的 HEAD/状态指针失效，这条讲计数类自述数字失效；后者更隐蔽，因为它不指向任何可以"对不上"的具体对象。
