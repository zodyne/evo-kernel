---
id: build-break-attribution-needs-counterfactual-revert
type: lesson
status: validated
scope: global
domain: code-review
tags: [code-review, adversarial, build-failure, counterfactual, attribution, readonly]
triggers:
  - "对抗复核『按卡/按脚本执行某处改动后构建失败』类发现，准备判 confirm/refuted 或给 severity"
  - "报错行号正好指向被指控的那一处改动，想只凭这条报错就归因（失败信号）"
  - "只复现了失败构建，没有『同源副本删掉/还原该行再构建』的对照（失败信号）"
  - "只读审查被审仓库，需要在不弄脏目标仓库的前提下证明某一处改动就是失败根因"
  - "同一份代码有失败与通过两个版本，要用 rc / 产物差异把变量隔离到一行"
created: 2026-09-21
evidence: {helpful: 0, harmful: 0}
verified_by: command
source: session:01a0b751-ed79-7475-af70-36c2c64d0a9c
last_verified: 2026-09-21
superseded_by: null
schema_version: 1
related: [adversarial-review-repro-as-written, adversarial-review-separate-evidence-from-impact-attribution, recommendation-strength-must-equal-evidence-strength]
---

# 构建失败要归因到单行：除复现外必须做反事实（删掉该行再构建）

**主张**：判「某处改动导致构建失败」时，先在全新 /tmp 同源副本上复现失败（configure + build，报错指到具体文件:行，如 `decoder.hpp:16:17: error: expected namespace name`，通用验收 `grep -c 'error:'` = 2），再在**同一副本**里删掉/还原被指控的那一行并重建：只有反事实侧变成 `rc=0` / `Built target`（本例 parity 目标），才能把失败归因到该行。报错行号 + 一次失败构建只说明「这里炸了」，不足以说明「就是这一行 / 别处没炸」。

**为什么**：编译错误只报第一现场，一处坏改动会在 include 闭包/下游 TU 里放大，日志里的 `error:` 计数是报错行数而不是根因数（本例单行注入 → 计数 2，还原后 rc=0）；反过来，一次失败构建里还混着环境、缓存、其他 WIP 改动等变量。反事实把「同一份输入、只差被指控的那一处」隔离成唯一变量，是判 severity 前最短路径的因果证据；只读审查要求注入与还原都做在 /tmp 副本内，目标仓库用 `git status --short` 留证。

**证据（切片命令 ↔ 结果）**：

- 在 /tmp 副本上模拟该发现（`python3` 改 `tools/parity/decoder.hpp`）后全新构建：`cmake -S repo -B b` ↳ `configure rc=0 … 未指定 CMAKE_BUILD_TYPE ⇒ 默认 Release(-O3)`；`cmake --build b -j … | tee out/build_literal.log | tail -20` ↳ 输出含 `In file included from /tmp/review-refute-…`，构造该行的 `decoder.hpp:16:17: error: expected namespace name` 出现，通用验收 `grep -c 'error:'` 得 2（要求 0）。
- 反事实（还原被指控行后再构建）：`=== rebuild parity target === rc=0 [81%] Built target core …`、`== parity-only rebuild after reverting the line == [100%] Built target …`；末条 assistant 记录「三条证据链（逐 TU 编译 / 全新 CMake 构建 / 反事实删行）全部独立复现」。
- 只读凭证：收尾 `git status --short && find . -name '*.o' -not -path './build/*'` ↳ 只有 `?? docs/ledger/2026-09-18-P1.0b/ ?? inc_types.cpp` 两个原本就存在的未跟踪项，无本次注入残留。

**边界 / 反例**：

- 反事实证明的是「该行**足以**导致失败」，不是「删掉它以后全树无其他问题」：本例反事实只重建了 parity 目标 / 通用验收，覆盖面以实际重跑的目标为限。
- 若失败来自两处改动的交互，或来自环境/缓存/编译器版本，单行反事实的 rc=0 会把因果归错；需要逐项拆变体或先固定环境。
- 切片截断了 build 日志与还原脚本的完整输出，本条只引用可见的 rc、行号与计数，不断言未显示目标也编过。
- 改动不可独立还原（多处交织）时，此法的隔离力下降，只能作旁证。

**失败信号（未来命中即该想起本条）**：构建失败的复核报告里只有「我复现了 rc≠0」而没有「删掉这行后再构建 rc=0」的对照；或把指向某行的第一条 error 直接当根因写进 severity，不先做反事实。
