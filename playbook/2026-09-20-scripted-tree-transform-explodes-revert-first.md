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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
已在本机实跑（macOS clang，/private/tmp/.../scratchpad/repro3）：\n\nʼʼʼ\nd=$(mktemp -d); cd $d; git init -q; mkdir src\ngit config user.email t@t; git config user.name t\nprintf 'struct Node { int v; };\\n' > src/h.h\nfor i in 1 2 3 4 5 6; do printf '#include \"h.h\"\\nint f%s(void){ struct Node n; n.v = %s; return n.v; }\\n' \"$i\" \"$i\" > src/u$i.c; done\ngit add -A && git commit -qm base\n\n# 有 bug 的变换：只改头（typedef 形态），漏了 use site 的 struct 标签\nsed -i '' 's/struct Node { int v; };/typedef struct { int v; } Node;/' src/h.h\nerr=$(for f in src/*.c; do clang -c -std=c99 -Isrc \"$f\" -o /dev/null 2>&1; done | grep -c 'error:'); echo \"err=$err\"   # err=6（每个 use site 一处 incomplete type 'struct Node'）\n\n# 回滚子树 → 修脚本（头 + use site 一起改）→ 重跑\ngit checkout -- src\nsed -i '' -e 's/struct Node { int v; };/typedef struct { int v; } Node;/' -e 's/struct Node/Node/g' src/h.h\nsed -i '' 's/struct Node/Node/g' src/u*.c\nerr=$(for f in src/*.c; do clang -c -std=c99 -Isrc \"$f\" -o /dev/null 2>&1; done | grep -c 'error:'); echo \"err=$err\"   # err=0\n\n# staged 细节：checkout -- . 撤不掉已 staged 的改动\nsed -i '' 's/struct Node { int v; };/typedef struct { int v; } Node;/' src/h.h; git add -A; git checkout -- .\necho \"dirty=$(git status --short | wc -l | tr -d ' ')\"        # 7\ngit reset -q && git checkout -- .; echo \"dirty=$(git status --short | wc -l | tr -d ' ')\"   # 0\nʼʼʼ\n实测输出依次为 err=6 / err=0 / dirty=7 / dirty=0。
```

**审核给出的修改意见（要点）**：1) 换证据：四条引用全部绑在已消失的 algommw-plus 会话态（/tmp/amw-p1.0b 沙箱、algommw-plus 的 2026-09-19 HEAD）上，且两条关键命令在切片里被 heredoc 截断、不能照抄重跑。改成写进 minimalRepro 的自包含复现（本机 clang + 临时 git 仓，err=6 → 回滚 → 修脚本 → err=0；外加 staged 细节 dirty=7 → reset+checkout → dirty=0），这同样满足 verified_by: command。若想保留会话出处，最多留一句「源自 2026-09-19 algommw-plus 命名收口会话（err=413 → checkout -- core → err=0）」，但不要当作可复跑证据。2) 收窄机制：把「几百个错误绝大多数是同一个脚本缺陷的放大」改为「本会话所见是同一缺陷（typedef 形态改造漏 use site 的 struct 标签）在数百个 use site 上的放大——切片只有一条样本错误行，未见逐类统计」，明确标注为推断。3) 其余（主张、边界、失败信号）保留：回滚优先于脏树手修这条主张本身是本机可复验的稳定属性，不因证据来源而失效。

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 几百个错误绝大多数是同一个脚本缺陷的放大（例如 typedef 形态改造漏了 use site 的 struct 标签）
- 逐条手修等于在错误的中间态上重复劳动，还会把「脚本产物」和「人工修补」混进同一个 diff，之后无法审计零行为

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
