---
id: diff-scope-subdir-filter-hides-sibling-changes
type: lesson
status: validated
scope: global
domain: design-review
tags: [acceptance-criteria, git-diff, scope, coverage, card-review]
triggers:
  - "验收判据里把 git diff 的路径写死成一个子目录：`git diff HEAD~1 -- core/src | grep -E '^[-+][^-+]'`，要判它能否证明『改动面已完整检查』"
  - "改动卡片/PLAN 只在一处写死作用域目录，而改动实际横跨两个同级目录（core/src 与 core/include）"
  - "验收输出计数看着正常（179 行都分类过），同级目录里却还有 30 行改动没有任何一条命令看过（失败信号）"
  - "头文件同时存在于两个目录（core/src 内的 .hpp 与 core/include/ 下的 .hpp），打算用目录而不是文件类型来划作用域"
  - "复核『证明/闸门命令漏了 X 目录』这类发现，要拿被排除目录的 diff 行数当实例数"
created: 2026-09-20
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b753-2b87-7475-af70-36c9e8959d50
last_verified: 2026-09-20
superseded_by: null
schema_version: 1
related: [acceptance-command-path-must-match-file-layout-table, blind-spot-claim-needs-instance-count]
---

**主张**：把「改动面已被完整检查」的证明命令写成 `git diff HEAD~1 -- <单个子目录>`，作用域外的同级目录会被**静默**排除——过滤路径不会报「我漏了什么」。这类证明必须同时跑一份覆盖全部改动路径的版本（`-- core` 或逐目录列举），并把被排除目录的 diff 行数当实例数报出来，证明才成立。

**为什么**：`git diff -- <path>` 是纯过滤器，输出看起来永远完整（179 行、每行都归类）。作用域写错时不会出现任何红/报错，只会少掉一整个目录。本例的坑更隐蔽：仓库里「头文件」按目录分布，`core/src` 下也有 `.hpp`、`core/include` 下也有 `.hpp`，于是用**目录**代替**文件类型**划作用域，必然一侧漏（core/include 的 30 行）一侧多。

**证据（切片命令 ↔ 结果）**：

- 卡片原文（作用域写死）：`grep -n 'diff 分类证明' PLAN.md` → `879:- diff 分类证明：\`git diff HEAD~1 -- core/src | grep -E '^[-+][^-+]'\` 的每一行属于且仅属于：\`namespace\` 开/闭、\`#include\`、\`#ifndef M_PI` …`。
- 卡片命令在字面重放树上的产出：`git diff HEAD~1 -- core/src | grep -E "^[-+][^-+]" | wc -l` → `179`；同一条命令换成 `-- core`（含头文件）后，切片里 `=== same but -- core (includes headers) ===` 的数字被截断（未记入本条主张）。
- 作用域外的实存量：`## extern"C" lines visible in core/include diff (invisible to card cmd): 30`；`git diff HEAD~1 -- core/include | grep 'extern "C"' …` → `27` 删 / `3` 增 —— 同一张卡片确实改了 `core/include`，而卡片的证明命令一条都看不到。
- 目录规模：`find core/src -type f | wc -l` = 38、`find core/include -type f | sort` = 29；批量改造的落点 `applied to 25 cpp and 3 hpp`（`.hpp` 落在 `core/src` 内），说明「头文件」不是一个目录能圈住的集合。

**边界 / 反例**：

- 改动面确实只有一个目录（且该结论另有证据）时，子目录作用域是正当用法；本条反对的是**没有核对过作用域边界**就用它下「完整」结论。
- 换成 `-- core` 会把 `build/`、`tests/` 之类一并卷进来，正解是「作用域 = 卡片允许改动的全部路径」，并把这份路径清单显式写在证明旁边，而不是随手挑一个名字好听的祖先目录。
- 本条只管「作用域是否覆盖改动面」，不负责给这条发现定阻塞性/严重度（见 related 的实例数条目）。

**失败信号（未来命中即该想起本条）**：证明命令里出现 `git diff HEAD~1 -- <单个子目录>`；报告写「改动面已 100% 分类/覆盖」却没说作用域边界；`git diff --stat` 里出现同级目录的文件名，但你的证明命令从没引用过那个目录。

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
R=$(mktemp -d); cd "$R"; git init -q .; git config user.email a@b.c; git config user.name a
mkdir -p core/src core/include
printf 'a\n' > core/src/a.cpp; printf 'b\n' > core/include/b.hpp; git add -A; git commit -qm base
printf 'a\nA\n' > core/src/a.cpp; printf 'b\nB\n' > core/include/b.hpp; git add -A; git commit -qm change
git diff HEAD~1 -- core/src | grep -cE '^[-+][^-+]'      # => 1  （同级 core/include 的改动静默消失，不报错）
git diff HEAD~1 -- core | grep -cE '^[-+][^-+]'          # => 2  （两侧都可见）
git diff HEAD~1 -- core/include | grep -cE '^[-+][^-+]'  # => 1  （被漏掉的那一侧）
实测输出：card-style(-- core/src)=1；full(-- core)=2；sibling(-- core/include)=1。命令不报任何「漏了什么」。本条主张在此自包含复现下成立。
```

**审核给出的修改意见（要点）**：主张本体（`git diff -- <单个子目录>` 是纯过滤器，作用域外的同级目录被静默排除）站得住，且有稳定、可本机复跑的真值——无需改写、无需降级。要改三处证据：  1) 硬错误：把「`27` 删 / `3` 增」改为正确读数——切片输出 `  27 -    3 @`，`27` 是 `-extern "C"` 删行，`3` 是 hunk 头（`@@ -34,8 +33,6 @@ extern "C" {`），新增 `extern "C"` 为 0 行。这是把一个计数误当「增」行。  2) 措辞收窄：把 `30` 从「作用域外的实存量 / 被排除目录的 diff 行数」改成「core/include diff 里 `extern \"C\"` 的行数（被排除改动的子集）」；若要「实例数」，直接用被排除目录的改动总量 270 行（card cmd 179 vs `-- core` 449，现已复跑得到），别用 30。触发语「同级目录里却还有 30 行改动没有任何一条命令看过」同步改为 270 行。  3) 换证据：证据节补上自包含最小复现（见 minimalRepro），不再把真值绑在 /tmp 沙箱 + algommw-plus 当时 HEAD 上——该 HEAD 现为 228f8ff，PLAN.md:879 已不含卡片原文，沙箱在 /tmp 不宜作长期证据（179 这一读数

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 证据节 `git diff HEAD~1 -- core/include | grep 'extern "C"' …` → `27` 删 / `3` 增 —— 「3 增」为切片与产物都不支持的误读：切片自身直方图是 `27 -` / `3 @`，`3` 是 hunk 头数，新增 `extern "C"` 实为 0 行（沙箱 `grep -c '^+.*extern "C"'` = 0）。
- 「作用域外的实存量：…core/include diff…: 30」及触发语「同级目录里却还有 30 行改动没有任何一条命令看过」——把 core/include diff 里 30 行 `extern "C"` 当成被排除目录的改动总量。实测被排除改动为 270 行（card cmd 179 vs `-- core` 449），30 只是单类行的子集，「30 行改动」低估约一个数量级。

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
