---
id: doc-algo-term-drift-variance-vs-range
type: lesson
status: candidate
scope: global
domain: doc-audit
tags: [doc-drift, code-review, semantic-drift, verification, doa]
triggers:
  - "核对文档断言与代码实况是否一致（评审/走查/验收）"
  - "文档用统计/算法术语描述实现（方差/均值/极差等），要确认代码是不是真这么算"
  - "只 grep 文档里的词去核对，却没确认实现字段名与判定表达式"
  - "发现文档描述的分流/判定机制与源码对不上（失败信号）"
  - "只读了文档描述就要下『实现如此』的结论"
created: 2026-09-16
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0a736-2f0d-7353-8a3d-430b0a337939
last_verified: 2026-09-16
superseded_by: null
schema_version: 1
related: [design-review-cross-check-implementation, doc-drift-fix-grep-by-concept]
---

文档断言与实现可能发生**算法术语语义漂移**，不是单纯重命名：algommw 的 DOA 1D/2D
分流，文档四处写「按 xPosZ **方差**自动分流」（COMPASS.md:114、CLAUDE.md:381），实现实为
**极差判定**——`geom.c:37-62` 遍历取 `xMin`/`xMax`，第 62 行
`return (uint8_t)((xMax - xMin) < (Real_t)0.25)`（步长 1 = λ/2 单位下即 λ/8）。

为什么：只 grep 文档里的词（`方差`/`variance`）会命中 CLAUDE.md 里「量化方差 = ΔR²/12」
这种不相关位置，或根本对不上实现的真实判据；「方差」（平方偏差均值）与「极差」（最大值减
最小值）是**不同运算**，术语漂移意味着文档的算法描述与实现不符，属真实 bug 而非措辞差异。

核对文档断言时，要**同时 grep 文档用词与实现字段名**（`xMin`/`xMax`/`xPosZ`/`bIs1D`），
并读源码的实际判定表达式，以源码为准——只信文档算法措辞会漏掉这类漂移。

边界：仅适用于「文档描述算法/判定机制、需与实现核对」的场景；纯命名漂移（重命名导致文档断链）
另见 `doc-drift-fix-grep-by-concept`；通用走查原则见 `design-review-cross-check-implementation`。

证据：`rg -n "xMin|xMax|xPosZ|方差|variance" ...` 命中 geom.c:39-40 的 `xMin`/`xMax` 字段；
`sed -n '60,75p' geom.c`（经 slice 末条）确认第 62 行极差阈值判定；对抗式验证结论
`refuted=false`（未能推翻该发现）。
