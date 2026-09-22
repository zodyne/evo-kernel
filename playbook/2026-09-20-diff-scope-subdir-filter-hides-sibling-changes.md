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
