---
id: make-nothing-to-be-done-check-cwd
type: lesson
status: candidate
scope: global
domain: build
tags: [make, cwd, build, debugging]
triggers:
  - make 报 "Nothing to be done for 'all'" 但你明明刚改了源码
  - make 报 "No rule to make target" 而目标名确定存在于项目里
  - 一条构建命令换了终端/会话后行为不一样
  - 在子目录（examples/test 等）里跑顶层项目的构建
created: 2026-08-01
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:da720f38-036f-42ec-820d-ce8538a4fc1f
last_verified: 2026-08-01
superseded_by: null
schema_version: 1
related: [claude-code-shell-cwd-reset-use-git-dash-c]
---

# make 报 "Nothing to be done" 先 pwd：很可能在错的目录跑了另一个 Makefile

`make` 报 `Nothing to be done for 'all'` **不等于**「构建已完成、产物是最新的」——它只说明**当前目录这份 Makefile** 的默认目标没事可做。子目录（如 `src/examples/xxx`）若有自己的 Makefile，在里面跑顶层项目的构建命令会得到这个迷惑性输出，而不是报错；指定目标则报 `No rule to make target`。

**处置**：先 `pwd && ls Makefile` 确认 cwd，然后用 `make -C <项目根绝对路径>` 代替依赖 cwd 的裸 `make`。

**证据**（session da720f38）：在 `libucm221/src/examples/faf_offline` 下连跑三条 `make CC=cc` 想构建顶层 `libSPX_ALG.dylib`，分别得到 "Nothing to be done" 和 "No rule to make target `libSPX_ALG.dylib'"；`pwd` 揭示在子目录；改 `make -C $L CC=cc` 后 `✓ 构建完成: libSPX_ALG.dylib`。
