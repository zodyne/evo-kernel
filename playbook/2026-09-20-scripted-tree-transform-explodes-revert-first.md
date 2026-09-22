---
id: scripted-tree-transform-explodes-revert-first
type: lesson
status: validated
scope: global
domain: refactoring
tags: [git, rollback, bulk-edit, scripted-transform, compile-errors]
triggers:
  - "脚本化全树改写（头 guard / typedef / 命名 / cast）一次炸出几百个编译错误"
  - "err=413 这类数字出现后，纠结是在脏树上手工续修还是回滚重来（失败信号：开始逐条手修）"
  - "变换脚本本身有 bug（断言失败 / 少处理一种形态），需要干净基线重跑"
  - "跑完自动改写工具后想重跑，但工作区已被它写脏"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b4a3-ae96-7475-af70-36ad39adaba4
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [mechanical-identifier-rename-cascades]
---

**主张**：脚本化全树改写一次报出数百个编译错误时，高效路径是**把子树回滚到干净基线（`git checkout -- <subtree>`），修脚本后重跑**；不要在爆炸的树上逐条手工修。本会话 `err=413` 后 `git checkout -- core`，用修正过的脚本重跑得到 `err=0`；更早一次变换脚本断言失败也走了同样的回滚。

**为什么**：几百个错误绝大多数是同一个脚本缺陷的放大（例如 typedef 形态改造漏了 use site 的 `struct` 标签），逐条手修等于在错误的中间态上重复劳动，还会把「脚本产物」和「人工修补」混进同一个 diff，之后无法审计零行为。回滚成本是一两条命令，重跑成本是脚本修一行。

**证据（本会话切片，命令 ↔ 结果）**：

- 一次全树改写（guard + typedef struct + 数组前缀）后：`guard OK @file 修 26 typedef struct 修 16 N8 数组 OK N8 闸门精化 OK err=413`。
- 紧随其后的命令是 `git checkout -- core && git status --short | wc -l && python3 - <<'PY' ...`（回滚 core 再重跑）；重跑结果为 `1 guard/@file/typedef 完成;typedef 文件数 16 N8 OK err=0`。
- 更早的 `/tmp/amw-p1.0b/transform.py`：首跑 `AssertionError`，随后 `git checkout -- core tests tools`，输出 `(tracked 已回滚, 新头保留)`，再修脚本重跑。
- 另一处同型：clang-tidy 写脏工作区后，用 `git reset -q && git checkout -- .` 清干净再跑，才得到 `tidy rc=0 errors=0`。

**边界 / 反例**：

- 回滚前要确认待回滚子树里没有本轮之外的人工改动；本会话都是脚本独占的子树，所以可直接 `checkout`。
- 若错误数是几十而不是几百、且已定位到少数几个文件，局部修比重跑更快；本条针对「同一缺陷放大」的爆炸形态。
- 用 `git checkout -- .` 不能撤销已 staged 的改动，需要先 `git reset`（本会话 clang-tidy 场景即如此）。

**失败信号（未来命中即该想起本条）**：看到 `err=NNN`（数百）后开始写逐文件修补脚本或手工改；或同一棵树反复重跑自动改写工具，报错数不降。
