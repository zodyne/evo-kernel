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

## 2026-09-22 独立复核增补

本条原证据绑在**已消失的 /tmp 沙箱**或**别的仓库当时 HEAD**上，引用命令在切片里被截断、不能照抄重跑。
下列是复核时在本机跑过的**自包含最小复现**（可当场重跑），据此本条留在注入集：

```
自包含、当场重跑（无外部依赖，只用 /usr/bin/c++）；已在 2026-09-22 实跑：

d=$(mktemp -d); cd "$d"
printf '#ifndef H\n#define H\n#include <cstddef>\nnamespace parity {\nusing namespace amw;\n}\n#endif\n' > dec.hpp
printf '#include "dec.hpp"\nint a(){return 0;}\n' > a.cpp; cp a.cpp b.cpp
c++ -std=c++17 -c a.cpp -o /dev/null 2> e1.log; echo "injected rc=$?"   # -> injected rc=1
c++ -std=c++17 -c b.cpp -o /dev/null 2>> e1.log
echo "count=$(grep -c 'error:' e1.log)"                                # -> count=2  (1 行注入 / 2 个 TU)
grep -m1 error: e1.log                                                 # -> ./dec.hpp:5:17: error: expected namespace name
printf '#ifndef H\n#define H\n#include <cstddef>\nnamespace parity {\n}\n#endif\n' > dec.hpp
c++ -std=c++17 -c a.cpp -o /dev/null 2> e2.log; echo "reverted rc=$?"   # -> reverted rc=0
echo "count=$(grep -c 'error:' e2.log || true)"                        # -> count=0

实跑输出（逐字）：injected rc=1 / second TU rc=1 / count=2 / ./dec.hpp:5:17: error: expected namespace name / reverted rc=0 / second TU rc=0 / count=0。
结论：单行注入 ⇒ 报错 + `grep -c 'error:'`=2（1 行根因、2 个 TU 各报一次）；还原该行 ⇒ rc=0、计数 0。与条目主张同构（本条目的 2↔0、rc≠0↔rc=0 都复现），只是锚点从 algommw-plus 换成本地最小件。
```

**审核给出的修改意见（要点）**：主张与边界本身站得住（反事实隔离是通用方法，本机已最小复现），故留注入集；但**证据节要换**：\n\n1) 证据节第 1 条的基石锚点 `decoder.hpp:16:17: error: expected namespace name` 在切片里**没有对应命令输出**（只出现在 assistant 自述，含它的 build 日志被截断）。把它降级为「assistant 自述」，primary 证据换成本机自包含最小复现（见 minimalRepro，已实跑：单行 `using namespace amw;` → `dec.hpp:5:17: error: expected namespace name`、`grep -c 'error:'`=2；还原该行 → rc=0、计数 0）。algommw-plus 的具体 rc=0/[81%]/[100%] 保留为旁注并标明「原会话命令尾部截断，不能照抄重跑」。\n\n2) 「为什么」段的机制句（include 闭包放大 / error 计数=报错行数非根因数）是条目作者的合成，切片未直接给出；最小复现已佐证其为通用编译器属性，故写成「通用属性」而非「由本切片观测所得」，避免把外部机制当观测。\n\n3) 「必须做反事实」的一般律可保留——条目的边界/反例节已自限（覆盖面以重跑目标为限、交互/环境致因会误归、不可独立还原时降为旁证），

**复核指出、尚未逐条改写进正文的断言**（读正文时以本节为准）：
- 编译错误只报第一现场，一处坏改动会在 include 闭包/下游 TU 里放大，日志里的 `error:` 计数是报错行数而不是根因数

**判定**：keep-with-fix · 拟留 playbook · 原证据快照风险=low · 复核时本机可复跑=true
